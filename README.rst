XCore Template HOWTO
====================

This repository provides a template for new repositories on the XCore
open source github repository site.
To create a new repository using this template
use the following steps. 

You can use these steps to create a local project to start coding your
own stuff. Later you may create an  empty repository on the XCore open
source github site (see
https://github.com/xcore/Community/wiki/Repository-management on how 
to do this) to share this with the world.

Requirements
------------

* Git installed locally
* Python installed locally (version 2.7)
* An new empty github repository
* A github account with ssh keys generated (see "Generate a Keypair" at http://help.github.com/)

Steps for creating a new repository/project
-------------------------------------------

#. Create a working directory (or use an existing one with other repositories in).

#. If it does not already exist, clone the xcommon repository from github::

     git clone ssh://git@github.com/xcore/xcommon.git

#. Clone the xcore_template repository from github::

     git clone ssh://git@github.com/xcore/xcore_template.git

#. Use the rename_repository script to rename xcore_template to your repository name. Run this script from the working directory above the xcore_template directory. For example to change the name to my_repo::

     python xcommon/util/rename_repository.py xcore_template my_repo

#. You can now change into the new my_repo directory::

     cd my_repo

   this will have its origin pointing at xcore/my_repo on github.

#. Either copy/modify the app_template, plugin_template and module_template directories to contain the source code for the apps, modules and plugins of the repository. Or copy in existing apps and modules from elsewhere. Make sure that any copied in directories have Makefiles/module_build_infos in a similar form to the template examples. Pay particular attention to the include part of an application Makefile. It should look like this::

   -include ../module_xcommon/build/Makefile.common
   -include ../../xcommon/module_xcommon/build/Makefile.common

#. Once you have your specific modules set up you can remove the template directories.
 
#. Code away.

#. If you want to sync this with an XCore open source repository you
   need to request a new repo with the same name (see https://github.com/xcore/Community/wiki/Repository-management on how 
   to do this) to share this with the world.Now you can stage all the new files and do the repositories first commit and push it to a newly created github repo with the same name. You can do that like this::

	git add -A
	git commit -am "First commit"
	git push -u origin master

#. Now you can remove this README.rst file, rename the README_template.rst file to README.rst, and fill in the blanks. Use ``git commit`` and ``git push`` as normal.



