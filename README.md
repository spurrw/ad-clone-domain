Clones certain aspects on an Active Directory domain to a target domain. This can be useful to clone many aspects of your production Active Directory to a test environment. This is what I use it for.

Open each script and change the default value for the $DC parameter to the DCs of your domain, or, just set those values in the CLI when running the scripts.
Run the export scripts in numerical order on the source domain.
Copy the exported data files to the target domain.
Run the import scripts in numerical order on the target domain.

This tool exports and imports the following:
- Organizational Units
- User accounts (all get disabled)
- Computer accounts (all get disabled)
- Security Groups with membership
- Group Policy Objects
  - Settings
  - Links
  - Permissions, including Security Filtering
  - WMI Filters

What you need to do manually:
- Group Managed Service Accounts must be created manually. I couldn't get the GMSA import working correctly.
- WMI Filters Must be linked to GPOs manually
- AD object permissions must be set manually

When importing users and computers, existing users from the source domain won't get modified in the target domain if they already exist in target, but new accounts will get created.
