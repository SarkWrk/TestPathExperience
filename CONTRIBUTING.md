# Hello!
Thank you for considering making an Issue/PR to this repo!

When you open an issue or make a pull request please follow this *non-extensive* rule set!
>[!NOTE]
>Make your Issue/PR titles shortened versions of why you're making one. You will explain in full the details inside it.

<hr>

## Table of Contents:
[Labelling Your PR/Issue](https://github.com/SarkWrk/TestPathExperience/blob/main/CONTRIBUTING.md#labelling-your-prissue)

[Making A Suggestion](https://github.com/SarkWrk/TestPathExperience/blob/main/CONTRIBUTING.md#making-a-suggestion)

[Making An Issue](https://github.com/SarkWrk/TestPathExperience/blob/main/CONTRIBUTING.md#making-an-issue)

[Making A PR](https://github.com/SarkWrk/TestPathExperience/blob/main/CONTRIBUTING.md#making-a-pr)

[Examples]()

<hr>

## Labelling Your PR/Issue

Please label your Issues and PRs correctly.
>[!IMPORTANT]
>When you create a PR/Issue, you have certain labels that can be added to it to make it more distinct. These options are:
>- **bug**             | *Used when you think that something isn't working correctly*
>- **documentation**   | *Used for improving documentation*
>- **enhancement**     | *Used when you are making a backwards-compatible suggestion/PR*
>- **expiremental**    | *Used when you are making a non-backwards-compatible suggestion/PR*
>- **question**        | *Used when you're unsure if you have found a bug, but still want to report it*
>- **suggestion**      | *Used when you want to make a suggestion*

>[!NOTE]
>When your Issue/PR has been seen, labels may be added to it or removed from it. These labels may include:
>- **attention**         | *Used for when a bug/question doesn't seem right due to how the script is coded*
>- **duplicate**         | *Used for when an Issue/PR is a duplicate of a different Issue/PR*
>- **help wanted**       | *Used for when an Issue/PR has a hard time being fixed, and external help would be heavily welcomed*
>- **noteabug**          | *Used for when an Issue/PR tagged with `question` or `bug` is not a bug*
>- **wonthappen**         | *Used for when an Issue/PR (bug, question, or suggestion) will not be worked on*

<hr>

## Making A Suggestion
>[!NOTE]
>When you are making a suggestion, do not follow the formatting guide for making an Issue or PR.

>[!CAUTION]
>Always label suggestions with the `suggestion` label and an appropriate `enhancement` or `expiremental` label.

When you are making a suggestion you have two options: making an Issue and making a PR.
If you're willing to put your code inside the codebase, make a PR. Otherwise, make an Issue.

### Making a suggestion through an Issue:
When you are creating your Issue, preface in the title that it's a suggestion via putting [SUGGESTION\] at the start of the title. And format your Issue like this:

**[Goal of the suggestion\]**

[Why you think this suggestion should be added\]

### Making a suggestion through a PR:
When you are creating your PR, preface in the title that it's a suggestion via putting [SUGGESTION\] at the start of the title. And format your PR like this:

**[Goal of the suggestion\] | [Stability of the code\]**

[Why you think this suggestion should be added\]

[If applicable: any documentation changes that should be added/removed due to your code changes\]

>[!CAUTION]
>When adding your code, always make sure to comment what important parts of your code do. E.g.: Functions and important variables.
>
>**Any non-commented PR suggestions will be closed without consideration.**

<hr>

## Making An Issue
When making an issue, please format your issue like this (formatting is not required, but warmly welcomed):

**Issue:**

[What the issue you're having/noticed is\]

[An explanation of what you think the issue is, and why you think it's an issue\]

**(IF AVAILABLE\) Evidence:**

[A video and/or image proof of what the issue is\]

[If the evidence is not **easily** able to be understood outside of context, please explain what is going on in your evidence\]

**(OPTIONAL\) How To Fix The Issue:**

[A description/explanation of how you think the issue can be fixed.\]

>[!IMPORTANT]
>**If you know how to code it and are willing to put it into the codebase, please make a [PR](https://github.com/SarkWrk/TestPathExperience/blob/main/CONTRIBUTING.md#making-a-pr) instead of an issue**

<hr>

## Making A PR
>[!NOTE]
>When making a PR, you understand that, if merged, your code will become a part of the codebase and may be removed or modified at any moment.
>
>You also understand that you will be given credit to for the code you contributed on. When accrediting you, if no external means of credit (like a Youtube channel/Discord username/etc) is provided, your GitHub profile with be credited.

When you are making a PR, please include the labels `enhancement` or `expiremental` depending on what you're changing.

If your code adds/removes any attributes or adds/removes any \*Events/\*Functions, include a `documentation` label and include any necessary documentation changes/additions.

Please format your PR like this (formatting is not required, but warmly welcomed):

**Issue:**

[What the issue you're having/noticed is\]

[An explanation of what you think the issue is, and why you think it's an issue\]

**Code:**

[What your code does\]

*Code stability:* [How stable your code is\]

**(If applicable) Documentation Changes:**

[Required changes to the documentation\]

>[!CAUTION]
>When adding your code, always make sure to comment what important parts of your code do. E.g.: Functions and important variables.
>
>**Any non-commented PR bug fixes will be closed without consideration.**

<hr>

## Examples
Note that the "Title" and "Labels" will be in brackets, as these aren't real issues/PRs.

### Issue Suggestion:
*[Title: "[SUGGESTION\] Make Rigs Do The Flop" | Labels: suggestion, enhancement\]*

**Goal: Make rigs sometimes do the flop when idled**

I think that this should be added as a possible idle animation because it's funny.

### PR Suggestion:
*[Title "[SUGGESTION\] Make Players Have Infinite HP" | Labels: suggestion, expiremental\]*

**Goal: Make Players Have Infinite HP | Code stability: Sometimes breaks when the player does not spawn in within 6 seconds, and when the player is lagging.**

This change should be added to players because the AI is too overpowered, and due to that this change will make it more fair for the players.

**Documentation Changes:**

+Invincibility
- boolean, writeable
- When set to true the player the script is parented will instantly regenerate lost HP when taking damage

### Issue:
*[Title "Rigs Shooting Does Not Choose Random Positions" | Labels: bug\]*

**Issue:**

When shooting raycast visualisations are turned on, the bullet tracers heavily favour specific spots around the target when shooting.

This is an issue because it shows that the way spread is calculated for shooting is not random, and instead appears to heavily favour specific angles.

**Evidence:**

![image](https://github.com/user-attachments/assets/3207ba71-275e-41e3-af84-22b8ade55adb)

In this picture, you can see the bullet tracers are heavily favouring the maximum y-spread angles instead of being randomly spread out.

### PR:
*[Title: "Missing Overload In the Shooting Raycast Operation" | Labels: bug\]*

**Issue:**

In the raycast function located in ShootingScript under the shooting function, the operation is missing a RaycastParams overload which causes the bullets to hit bullet tracers instead of ignoring them.

This is an issue because it causes the raycasting function to consider every single part in the workspace instead of every part except from specified folders.

**Code:**

What my code does is add the already defined RaycastParams to the overload list of the raycast.

*Code stability:* Fully stable
