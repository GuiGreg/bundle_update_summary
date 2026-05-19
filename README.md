
# Bundle Update Summary
Print a readable summary after running `bundle update`

<img width="414" height="204" alt="Screenshot 2026-05-19 at 8 50 52 AM" src="https://github.com/user-attachments/assets/2836047f-e565-474e-a2c1-1e0a63ba6d29" />

# How to use?
1. Create the file `~/bundle_update_summary.sh`
2. Add command to your profile `~/.zshrc`
   ```
   bundle() {
     if [[ "$1" == "update" ]]; then
       shift
       ~/bundle_update_summary.sh "$@"
     else
      command bundle "$@"
     fi
    }
   ```
3. Reload shell `source ~/.zshrc`
