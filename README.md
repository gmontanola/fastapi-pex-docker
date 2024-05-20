# Python + PEX + Docker (🐍 + 🥚 + 🐳)
## Introduction
This is a simple example of how to use PEX to build nicely layered Docker images and also a way to learn about it by playing with it.

## Prerequisites
- Docker
- Python `>=3.11` and `<3.13`
- [PEX](https://docs.pex-tool.org/index.html)
- [Poetry](https://python-poetry.org/)
- _[Just](https://just.systems/man/en/chapter_4.html)_

_Just is optional but really helpful_

## But wait... What is PEX?
### Claude Opus answer
PEX (*P*ython *EX*ecutable) is a tool for creating self-contained executable packages from Python code. Here are the key points about PEX:

- It packages Python code and its dependencies into a single executable file with a `.pex` extension
- The `.pex` file can be run on any machine with a compatible Python interpreter, without needing to install dependencies separately
- This simplifies deployment and distribution of Python applications in a self-contained manner
- PEX analyzes the imports in your code to determine the required dependencies
- It fetches the dependencies from PyPI or other configured repositories and bundles them into the executable
- PEX supports packaging Python code that uses either the older `setup.py` or the newer `pyproject.toml` configuration.
- The generated `.pex` file can be executed like any other executable, for example:

  ```bash
  ./myapp.pex
  ```

In summary, PEX is a handy tool that simplifies packaging and deploying Python applications by creating portable executable packages with all dependencies included.

### My take
PEX is yet another take on Python packaging and distribution. It is *not a silver bullet*, you still have to mind platform specific peculiarities and the you still need to have a compatible Python interpreter installed to use PEX files. It's not new (1.0 in 2015), the documentation is lacking and there are few resources (from StackOverflow questions to random blog posts) to help you out.

I understand PEX may be useful for library maintainers to create standalone executables thus facilitating the distribution. But the [PEX in a Container](https://docs.pex-tool.org/recipes.html#pex-app-in-a-container) section of the documentation caught my attention.

## PEX "installation"
I followed the official [docs](https://docs.pex-tool.org/buildingpex.html#building-pex-files) to install it. Basically you just
need to bootstrap PEX with itself inside a Python virtual environment and then move it to a folder that is in your `PATH`.

```bash
python -m venv .venv
source .venv/bin/activate
pip install pex
pex pex requests -c pex -o ~/.local/bin/pex
```

## How it works (roughly)
1. Build a PEX file with the dependencies
2. Build a PEX file with the source code
3. Build a Docker image with the dependencies
4. Build another Docker image with the source code
5. Build yet another Docker image with the application, merging the two previous images.

```bash
pex -r requirements.txt -o build/deps.pex --include-tools --platform="manylinux2014_aarch64-cp-311-cp311" --layout=packed
pex -o build/src.pex --include-tools --platform="manylinux2014_aarch64-cp-311-cp3111" --layout=packed -P appex
docker build . -t ttl.sh/apppex:deps --file Dockerfile.deps
docker build . -t ttl.sh/apppex:src --file Dockerfile.src
docker build . -t ttl.sh/apppex:app --file Dockerfile.app
docker run -p 8000:8000 ttl.sh/apppex:app -m uvicorn appex.main:app --host 0.0.0.0
```

### If you have Just installed
```bash
just build
just run-docker
```

Use `just --list` to check other available commands.

## Some details
### PEX building
* PEX can read the dependencies from the `pyproject.toml` file, but I'm using a `requirements.txt` exported from Poetry. Why? I wanted two different PEX files (one for the dependencies and one for the source code) and if I use the whole project (`pex .`) the source code will be included in the PEX file.

* I'm working on *MacOS* and if I don't use the `--platforms` flag, the PEX file will be built for the current platform. Doing so I won't be able to create a Docker image since it will look for the wrong _wheels_ (`.whl` files) in the PyPI.

### Docker building
* Yeap I know I could use just one multi-layered `Dockerfile` to build the images. But I wanted to try something new and also tag the intermediary images.

* If we had only one PEX file with both dependencies and source code the `venv --scope=deps/source` could extract what we need from each stage without the need of two PEX files (it's done like this in the documentation).

* PEX will not package your assets and non-project files. If you need to include assets, do it in `Dockerfile.app`.

## Pantsbuild
### Why didn't I use [Pants](https://www.pantsbuild.org/2.20/docs/python/overview/pex) make everything *WAY easier*?
I like to learn things as raw as possible. If you are thinking about production grade, Pants will cover you and avoid all the hacky stuff done here.

## Why...
* *Poetry* - muscle memory
* *FastAPI* - it's what the cool kids are using
* *Mounting* a SQLite database in the container - this is really just an example.
