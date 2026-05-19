# Bundle Update Summary
Print a readable summary after running bundle update

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
