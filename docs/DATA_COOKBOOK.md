# DevOps Data Manipulation Cookbook for Nushell

A practical guide for working with JSON, YAML, and structured data from tools like **AWS CLI**, **Chef Knife**, **Kubectl**, and **REST APIs** in Nushell.

---

## 1. Golden Rules of Data in Nushell

1. **`open` auto-parses files:**
   You do not need `from json` or `from yaml` when reading files on disk. Nushell detects the extension automatically:
   ```nu
   open config.json    # Loads directly into a table or record
   open server.yaml    # Loads directly into a table or record
   ```

2. **External CLI output needs `from <format>`:**
   External binaries output text streams to stdout. Use `from json` or `from yaml` to turn their output into Nushell tables:
   ```nu
   aws ec2 describe-instances | from json
   kubectl get pods -o yaml | from yaml
   ```

3. **`explore` is your interactive inspector:**
   Pipe *any* command or data structure into `explore` to browse it in an interactive TUI spreadsheet with cursor navigation, search, and deep-object drill-down:
   ```nu
   aws ec2 describe-instances | from json | explore
   ```

---

## 2. AWS CLI Recipes

### Recipe 1: List Running EC2 Instances with IPs and Names
The AWS CLI returns a nested `Reservations -> Instances` structure. In Nushell, un-nesting this is effortless:

```nu
# List instance ID, type, state, and private IP:
aws ec2 describe-instances --output json
| from json
| get Reservations.Instances
| flatten
| where State.Name == "running"
| select InstanceId InstanceType PrivateIpAddress

# Extract the 'Name' tag cleanly:
aws ec2 describe-instances --output json
| from json
| get Reservations.Instances
| flatten
| insert Name { |row|
    $row.Tags?
    | default []
    | where Key == "Name"
    | get Value.0?
    | default "-"
  }
| select Name InstanceId InstanceType PrivateIpAddress State.Name
```

> [!TIP]
> **Use the Toolbox helper `aws.ec2` (or `aws-ec2-nu`):**  
> We built this exact un-nesting and tag extraction into `aws.ec2` in `toolbox/shell/modules/aws.nu`. You can query instances directly with zero boilerplate:
> ```nu
> # All running instances:
> aws.ec2 | where state == "running"
> 
> # Filter by name pattern or instance type:
> aws.ec2 | where name =~ "prod" | select name id type private_ip
> 
> # Quick positional filter (by name substring or i-xxxx):
> aws.ec2 web-01
> 
> # Query by custom tag:
> aws.ec2 | where tags.Environment? == "production"
> 
> # Find local SSH key pair:
> aws.ec2-key web-01
> ```

### Recipe 2: Quick Caller Identity / Account Check
```nu
# Convert caller identity to a clean single-row record:
aws sts get-caller-identity --output json | from json

# Just get your AWS Account ID:
aws sts get-caller-identity --output json | from json | get Account
```

### Recipe 3: Audit S3 Buckets
```nu
# List buckets sorted from newest to oldest:
aws s3api list-buckets --output json
| from json
| get Buckets
| sort-by CreationDate --reverse
```

### Recipe 4: Security Groups Audit
```nu
# Find all security groups allowing port 22 (SSH):
aws ec2 describe-security-groups --output json
| from json
| get SecurityGroups
| select GroupId GroupName IpPermissions
| where { |sg|
    $sg.IpPermissions
    | any { |rule| ($rule.FromPort? == 22) or ($rule.ToPort? == 22) }
  }
| select GroupId GroupName
```

---

## 3. Chef Knife Recipes

### Recipe 1: Search Nodes and Tabulate Attributes
Instead of fighting with `knife search`'s text formatter or piping to `awk`, ask for `-F json`:

```nu
# Search nodes by role and tabulate results:
knife search node "role:web" -F json
| from json
| get rows
| select name automatic.ipaddress chef_environment

# Filter by environment:
knife search node "*:*" -F json
| from json
| get rows
| where chef_environment == "production"
| select name automatic.ipaddress automatic.platform
```

### Recipe 2: Inspect a Single Node's Nested Attributes
```nu
# Load node JSON:
let node = (knife node show my-server-01 -F json | from json)

# Inspect run_list:
$node.run_list

# Check if a specific recipe is in run_list:
"recipe[base::security]" in $node.run_list

# Drill into deep attributes:
$node.default.my_app.database.host
```

### Recipe 3: List Cookbooks / Roles
```nu
# Search roles and extract their descriptions:
knife role list -F json
| from json
| transpose role_name info
| select role_name info.description
```

---

## 4. Kubernetes (`kubectl`) Recipes

### Recipe 1: Filter Pods by Status & Container Images
```nu
# List all pods across all namespaces:
kubectl get pods -A -o json
| from json
| get items
| select metadata.namespace metadata.name status.phase

# Find non-running or failed pods:
kubectl get pods -A -o json
| from json
| get items
| where status.phase != "Running"
| select metadata.namespace metadata.name status.phase

# Extract container images used in a namespace:
kubectl get pods -n default -o json
| from json
| get items.spec.containers
| flatten
| select name image
| uniq
```

### Recipe 2: Node Resource Capacity
```nu
# Inspect CPU and Memory capacity across cluster nodes:
kubectl get nodes -o json
| from json
| get items
| select metadata.name status.capacity.cpu status.capacity.memory
```

---

## 5. Essential Nushell Data Operators Cheat Sheet

### 1. `get` — Deep Navigation
Navigates through records, lists, and tables:
```nu
$data | get foo.bar.0.baz
# Safe navigation (returns null instead of erroring if key doesn't exist):
$data | get foo.bar?.baz?
```

### 2. `select` vs. `reject`
```nu
# Keep only specified columns:
$table | select name size modified

# Remove unwanted columns:
$table | reject temporary_field debug_info
```

### 3. `where` — Filtering
```nu
# Equality:
$table | where status == "active"

# Regex matching:
$table | where name =~ "prod-.*"

# Numerics / Filesizes / Dates:
$table | where size > 10mb
$table | where modified > (date now - 7day)

# Closures (complex logic):
$table | where { |row| ($row.cpu > 80) and ($row.env == "prod") }
```

### 4. `sort-by`
```nu
$table | sort-by modified --reverse
$table | sort-by size -r
```

### 5. `insert` & `update` — Column Calculations
```nu
# Add a new calculated column:
ls | insert is_big { |row| $row.size > 1mb }

# Update an existing column:
$nodes | update ipaddress { |row| $"10.0.($row.ipaddress)" }
```

### 6. `flatten` — Un-nesting
Flattens a list of lists into a single list, or nested tables:
```nu
[[1, 2], [3, 4]] | flatten     # -> [1, 2, 3, 4]
$reservations.Instances | flatten
```

### 7. `transpose` — Key-Value Inversion
Converts a Record (`{ a: 1, b: 2 }`) into a Table (`column0 | column1`), or vice versa:
```nu
# Record to Table:
{ host: "localhost", port: 8080 } | transpose key value

# Table to Record:
[[key, value]; [host, "localhost"] [port, 8080]] | transpose -r -d
```

### 8. `group-by` & Aggregations
```nu
# Group files by extension:
ls | group-by { path parse | get extension }

# Count items per group:
ls | group-by type --to-table | update items { length }
```

### 9. Exporting Data
Nushell can export any table to JSON, YAML, CSV, or Markdown:
```nu
# Convert table to YAML:
$my_table | to yaml

# Export to a formatted Markdown table:
$my_table | to md

# Save to file:
$my_table | to json | save -f output.json
$my_table | to csv | save -f export.csv
```
