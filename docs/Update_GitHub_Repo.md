# Updating Changes to GitHub: Step-by-Step Guide

This guide will help you update your GitHub repository after making changes in your local folder.

---

## Step 1: Navigate to Your Local Repository
Open a terminal and go to your local repository folder:
```bash
cd /path/to/your/local/repo
```

---

## Step 2: Check the Status of Changes
Run the following command to see what has been modified:
```bash
git status
```
This will show the files that have been added, modified, or deleted.

---

## Step 3: Add Changes to the Staging Area
To stage all changes in the repository, use:
```bash
git add .
```
If you want to stage specific files, use:
```bash
git add <filename>
```

---

## Step 4: Commit the Changes
Create a commit with a descriptive message:
```bash
git commit -m "Your descriptive commit message here"
```

---

## Step 5: Push Changes to GitHub
Upload the changes to the remote repository:
```bash
git push origin main
```
- Replace `main` with your branch name if you are working on a branch other than `main`.

---

## Optional: Pull Remote Changes Before Pushing
If your repository might have been updated remotely (e.g., by a collaborator), pull the latest changes first to avoid conflicts:
```bash
git pull origin main
```

---

## Step 6: Verify the Changes
Go to your GitHub repository in your web browser and confirm that the changes have been applied.

---

## Troubleshooting
- **Error: "not a git repository":**
  Ensure you’re inside the correct local repository folder before running Git commands.
- **Merge conflicts:**
  If you encounter conflicts during a `git pull`, resolve them manually, then commit and push again.
- **Permission errors:**
  Ensure your SSH key is configured correctly.

You’re all set to update your GitHub repository!
