FROM ruby:2.3

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY src/Gemfile /usr/src/app
COPY src/Gemfile.lock /usr/src/app
RUN bundle install

COPY src /usr/src/app
RUN RAILS_ENV=production rake db:migrate && rake assets:precompile

EXPOSE 3000

CMD ["rails", "s", "-b", "0.0.0.0", "-e", "production"]
