set shell := ["bash", "-cu"]

deps_pex := "build/deps.pex"
src_pex := "build/src.pex"
docker_registry := "ttl.sh/appex"
python_version := "311"
default: build-native run-pex

build-deps-pex:
    pex -r requirements.txt -o {{ deps_pex }} --include-tools --platform="manylinux2014_aarch64-cp-{{ python_version }}-cp{{ python_version }}" --layout=packed

build-src-pex:
    pex -o {{ src_pex }} --include-tools --platform="manylinux2014_aarch64-cp-{{ python_version }}-cp{{ python_version }}" --layout=packed -P appex

build-native-deps:
    pex -r requirements.txt -o dist/deps.pex --include-tools

build-native-src:
    pex -o dist/src.pex --include-tools -P appex

build-docker-deps:
    docker build -t {{ docker_registry }}:deps -f Dockerfile.deps .

build-docker-src:
    docker build -t {{ docker_registry }}:src -f Dockerfile.src .

build-docker-app:
    docker build -t {{ docker_registry }}:app -f Dockerfile.app .

push-docker-deps:
    docker push {{ docker_registry }}:deps

push-docker-src:
    docker push {{ docker_registry }}:src

push-docker-app:
    docker push {{ docker_registry }}:app

build-deps: build-deps-pex build-docker-deps

build-src: build-src-pex build-docker-src

build-app: build-docker-app

# Build packed PEX app
build-pex: build-deps-pex build-src-pex

# Build Docker images
build-docker: build-docker-deps build-docker-src build-docker-app

# Build packed PEX and Docker images
build: build-pex build-docker

# Push Docker images
push: push-docker-deps push-docker-src push-docker-app

# Build everything and push Docker images
build-and-push: build push

# Build native PEX zipapp
build-native: build-native-deps build-native-src

# Start FastAPI using Docker
run-docker:
    docker run -p 8000:8000 {{ docker_registry }}:app -m uvicorn appex.main:app --host 0.0.0.0

# Run native PEX zipapp and start FastAPI
run-pex:
    PEX_PATH=dist/deps.pex python dist/src.pex -m uvicorn appex.main:app --host 0.0.0.0
