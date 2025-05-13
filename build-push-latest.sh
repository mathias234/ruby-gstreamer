docker build -t ruby-gstreamer .
docker tag ruby-gstreamer:latest mathias234/ruby-gstreamer:latest
docker push mathias234/ruby-gstreamer:latest
