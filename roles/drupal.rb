name "drupal-all-in-one"
description "Role for using drupal on a single node"

run_list(
  "recipe[build-essential]",
  "recipe[mysql]",
  "recipe[drupal]",
  "recipe[drupal::drush]"
)


