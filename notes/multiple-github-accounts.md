# Multiple GitHub Accounts Setup Guide

This guide helps you configure multiple GitHub accounts (work and personal) 
on a single computer, with work as default.

## Prerequisites

- Git installed
- Access to both GitHub accounts

## Step 1: Generate SSH Keys

Generate separate SSH keys for each account:

```bash
ssh-keygen -t ed25519 -C "work@email.com" -f ~/.ssh/id_ed25519_work
ssh-keygen -t ed25519 -C "personal@email.com" -f ~/.ssh/id_ed25519_personal
```

Press Enter when prompted for passphrase (or set one for security).

## Step 2: Add SSH Keys to GitHub

**Get your public keys:**

```bash
cat ~/.ssh/id_ed25519_work.pub
cat ~/.ssh/id_ed25519_personal.pub
```

**Add to GitHub:**

1. Copy the work public key
2. Go to https://github.com/settings/keys (logged in as work account)
3. Click "New SSH key"
4. Paste the key and save

5. Log out and log into personal account
6. Go to https://github.com/settings/keys
7. Click "New SSH key"
8. Paste the personal public key and save

**Important:** Each key must be added to its respective account only.

## Step 3: Configure SSH

Create or edit `~/.ssh/config`:

```bash
nano ~/.ssh/config
```

Add this configuration:

```text
# Work account (default)
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work
    IdentitiesOnly yes

# Personal account
Host github.com-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal
    IdentitiesOnly yes
```

Save and set permissions:

```bash
chmod 600 ~/.ssh/config
```

## Step 4: Add Keys to SSH Agent

```bash
ssh-add -D
ssh-add ~/.ssh/id_ed25519_work
ssh-add ~/.ssh/id_ed25519_personal
```

Verify keys are added:

```bash
ssh-add -l
```

## Step 5: Configure Git

**Set work account as global default:**

```bash
git config --global user.name "Your Work Name"
git config --global user.email "work@email.com"
```

**Set up automatic switching for personal folder:**

Edit `~/.gitconfig`:

```bash
nano ~/.gitconfig
```

Add at the end:

```text
[includeIf "gitdir:~/personal/"]
    path = ~/.gitconfig-personal
```

Create `~/.gitconfig-personal`:

```bash
nano ~/.gitconfig-personal
```

Add:

```text
[user]
    name = Your Personal Name
    email = personal@email.com
```

## Step 6: Test Your Setup

**Test SSH connections:**

```bash
ssh -T git@github.com
ssh -T git@github.com-personal
```

Expected output:
```text
Hi WorkUsername! You've successfully authenticated...
Hi PersonalUsername! You've successfully authenticated...
```

**Test git config:**

```bash
# In any folder (should show work)
git config user.email

# In ~/personal/ folder (should show personal)
cd ~/personal
git config user.email
```

## Usage

### Cloning Repositories

**Work repos (anywhere):**

```bash
git clone git@github.com:company/repo.git
```

**Personal repos (option 1 - in ~/personal/ folder):**

```bash
mkdir -p ~/personal
cd ~/personal
git clone git@github.com-personal:username/repo.git
```

**Personal repos (option 2 - anywhere):**

```bash
git clone git@github.com-personal:username/repo.git /any/path
```

### Pushing Changes

**Work repos:** Push normally

```bash
git push origin main
```

**Personal repos:** 
- If in `~/personal/` folder or cloned with `github.com-personal`, 
  push normally
- Otherwise, update remote first:

```bash
git remote set-url origin git@github.com-personal:username/repo.git
git push origin main
```

### Force Personal Account in Any Folder

**Method 1: Local config (per repository)**

```bash
cd /path/to/repo
git config user.name "Your Personal Name"
git config user.email "personal@email.com"
git remote set-url origin git@github.com-personal:username/repo.git
```

**Method 2: Add more folders to ~/.gitconfig**

```text
[includeIf "gitdir:~/personal/"]
    path = ~/.gitconfig-personal

[includeIf "gitdir:~/side-projects/"]
    path = ~/.gitconfig-personal
```

## Troubleshooting

**Both accounts show the same username:**
- Ensure each SSH key is added to only one GitHub account
- Clear and re-add keys: `ssh-add -D` then add them again
- Verify with: `ssh -T -v git@github.com 2>&1 | grep "Offering"`

**Permission denied:**
- Check keys are added: `ssh-add -l`
- Verify SSH config syntax
- Ensure public keys are on GitHub

**Wrong email in commits:**
- Check: `git config user.email`
- Set locally: `git config user.email "correct@email.com"`
- Check folder path matches includeIf pattern

## Quick Reference

```bash
# Test connections
ssh -T git@github.com
ssh -T git@github.com-personal

# Check current config
git config user.name
git config user.email

# Check remote URL
git remote -v

# View commit author
git log -1 --pretty=format:"%an <%ae>"

# List SSH keys
ssh-add -l
```
