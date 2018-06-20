FROM anthonyamanse/swift-ubuntu:4.2-SNAPSHOT
# temporary snapshot image (no automated build as of yet)

ENV DEBIAN_FRONTEND noninteractive

# Install Swift Kuery PostgreSQL dependency
RUN apt-get update && apt-get install -y \
    libpq-dev \
 && rm -rf /var/lib/apt/lists/*

COPY Sources /Kitura-Project/Sources
COPY Tests /Kitura-Project/Tests
COPY Package.swift /Kitura-Project
COPY Package.resolved /Kitura-Project
COPY LICENSE /Kitura-Project
COPY .swift-version /Kitura-Project

WORKDIR /Kitura-Project

RUN swift build

CMD [ "swift", "run", "--skip-build" ]
