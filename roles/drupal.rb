name "drupal-all-in-one"
description "Role for using drupal on a single node"

run_list(
  "recipe[drupal]",
  "recipe[drupal::drush]"
)

override_attributes(
  :db => {
    :user => "pictonio",
    :password => "pictonio",
    :database=> "pictonio"
  }
)

