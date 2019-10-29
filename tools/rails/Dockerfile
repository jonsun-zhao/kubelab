FROM ruby:2.4

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app
COPY src/Gemfile /usr/src/app
COPY src/Gemfile.lock /usr/src/app
RUN bundle install

COPY src /usr/src/app

EXPOSE 3000

CMD ["./run.sh"]
