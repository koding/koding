###
## Template for creating a single window KDApplication

##\#Require the KDFramework
Assign variables to the classes you need from KDFramework with
{ className1, className2 } = framework
###

framework = requirejs 'Framework'
{
  KDView
  KDViewController
} = framework