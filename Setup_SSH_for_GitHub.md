# Setting Up SSH for GitHub: Step-by-Step Guide

This guide will help you set up SSH for your GitHub repository access.

---

## Step 1: Check for an Existing SSH Key
Run the following command to check if you already have an SSH key:
```bash
ls -al ~/.ssh
```
If you see files like `id_rsa` and `id_rsa.pub`, you already have an SSH key.

---

## Step 2: Generate a New SSH Key (If Needed)
If no SSH key exists, generate one:
```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```
- Replace `your_email@example.com` with your GitHub email.
- Save the key as `~/.ssh/id_rsa` or any custom name you prefer.

---

## Step 3: Add the SSH Key to the SSH Agent
Start the SSH agent:
```bash
eval "$(ssh-agent -s)"
```
Add your SSH key to the agent:
```bash
ssh-add ~/.ssh/id_rsa
```

---

## Step 4: Copy the Public Key
Copy the contents of your public key:
```bash
cat ~/.ssh/id_rsa.pub
```
The output will look like:
```
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQE... your_email@example.com
```
Copy **everything** from `ssh-rsa` to the end.

---

## Step 5: Add the SSH Key to GitHub
1. Go to [GitHub SSH Key Settings](https://github.com/settings/keys).
2. Click **New SSH Key**.
3. In the "Title" field, enter a name (e.g., "My Laptop Key").
4. Paste the copied key into the "Key" field.
5. Click **Add SSH Key**.

---

## Step 6: Test the SSH Connection
Run the following command to test the connection:
```bash
ssh -T git@github.com
```
If successful, you'll see:
```
Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.
```

---

## Step 7: Clone Your Repository
Clone your repository using the SSH URL:
```bash
git clone git@github.com:username/repository-name.git
```
Replace `username` and `repository-name` with your GitHub username and the repository name.

---

## Troubleshooting
- **Permission denied (publickey):**
  - Ensure the key is added to the SSH agent: `ssh-add ~/.ssh/id_rsa`.
  - Verify the key is added to GitHub.
- **Wrong repository URL:** Ensure you use the SSH URL (e.g., `git@github.com:username/repository-name.git`).

You’re all set!
