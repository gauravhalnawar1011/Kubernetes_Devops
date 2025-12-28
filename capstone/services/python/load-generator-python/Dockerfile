FROM python:3.12-slim AS generate-requirements
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:$PATH"
# Export is provided by a plugin in newer versions of poetry 
RUN poetry self add "poetry-plugin-export[requirements]"
COPY pyproject.toml poetry.lock ./
RUN poetry export --output requirements.txt

# ###

FROM python:3.12-slim AS production
COPY --from=generate-requirements /requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . . 
CMD ["python", "main.py"]