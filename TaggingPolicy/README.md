Tagging Policy that does the following:

- Requires a list of tags in the main.tf to be on every resource group during creation
- All resources within each resource group inherit tags from the rg
- Has an allowed value list for each tag in the terraform.tfvars
- This only creates the defentions/Initative, these still need to be assigned to take effect
       - Reccomend assigning to smaller scope test sub/rg before assiging to top level management group
