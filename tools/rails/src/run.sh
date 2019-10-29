#!/bin/bash

rake db:exists || rake db:setup

rake db:migrate 

if [ $RAILS_ENV -eq "production" ]; then
  rake assets:precompile
fi

rails s -b 0.0.0.0