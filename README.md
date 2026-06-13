# Nix-Git-Cherry-Picker

This small shell script helps cherry-picking commits between two git branches (supposedly used as a nix configuration on two machines).

It does not handle merge conflicts automatically. It will instruct you to do it yourself.
#### Installation

##### Nix

In your flake.nix :
```nix
nix-git-cherry-picker = {
    url = "github:tomasriveral/nix-git-cherry-picker";
};
```
Or, if you want to follow the inputs :
```nix
nix-git-cherry-picker = {
  url = "github:tomasriveral/nix-git-cherry-picker";
  inputs.flake-utils.follows = "flake-utils";
  inputs.nixpkgs.follows = "nixpkgs";
};
```
You can refer to the package as `inputs.nix-git-cherry-picker.packages.${pkgs.system}.default`
##### Manual

```sh
git clone https://github.com/tomasriveral/Nix-Git-Cherry-Picker
cd Nix-Git-Cherry-Picker
./ngcp.sh
```
#### Usage

For best practices (and to avoid merge conflicts), you should push to your remote before shutting down your machine or running ngcp from another machine.

```
Usage: ngcp [mode] [options]
Mode:
 pick <commit 1> <commit2> <...>    Cherry-pick commits for the remote branch.
 pull                               Pulls the changes to the local branch.
Options:
  --automatic                       Exit with no changes if merge conflict and instructs the user to pull manually. Use this option for automation.
```
#### Configuration

The programs will create a default configuration if the `~/.config/nix-git-cherry-picker/config.json` doesn't exist.

```json
{
  "localBranch": "laptop",
  "remoteBranch": "desktop",
  "nixConfigPath": "/home/tomasr/nixos/"
}
```

`localBranch` is the git branch on your current machine.

`remoteBranch` is the git branch on your other machine.

`nixConfigPath` is the path to your cloned git repository.

#### Note
This project was primarily designed to handle [my nixos configuration](github.com/tomasriveral/nixos) and, as such, meets my needs. This means that :

* Even though this project could actually work for any other git project (nixos configuration or not, hosted on github or not), I do not guarantee it will stay like that. I might add a nix-specific feature in the future.
* It only works on two branches. (You could reuse the same branch on multiple machines).

If you want to use this project for other purposes, you are free to open a PR or ask kindly, I might implement (or not) modifications.
