## Codebase Analysis: Qdrant MCP Server

### **Overview**

This is a **Model Context Protocol (MCP) server** that provides semantic search capabilities using Qdrant vector database with multiple embedding providers. It enables AI assistants to perform vector search operations through a standardized MCP interface.

---

## **Tech Stack**

### Core Technologies

- **Runtime**: Node.js 20+ (TypeScript/ES Modules)
- **Language**: TypeScript 5.7+ with strict mode
- **Vector Database**: Qdrant (via Docker)
- **MCP SDK**: `@modelcontextprotocol/sdk` v1.0.4
- **Testing**: Vitest (422 tests, 98%+ coverage)
- **Code Quality**: Biome (formatting/linting), Husky (git hooks), Commitlint

### Key Dependencies

- **Embedding Providers**: OpenAI, Cohere, Voyage AI, Ollama (local)
- **Rate Limiting**: Bottleneck for API throttling
- **Validation**: Zod for schema validation
- **Transport**: stdio (local) or HTTP (remote)

---

## **Architecture**

### **Directory Structure**

```
src/
├── embeddings/          # Embedding provider implementations
│   ├── base.ts         # Common interfaces
│   ├── factory.ts      # Provider factory pattern
│   ├── ollama.ts       # Local Ollama provider
│   ├── openai.ts       # OpenAI provider
│   ├── cohere.ts       # Cohere provider
│   ├── voyage.ts       # Voyage AI provider
│   └── sparse.ts       # BM25 sparse vectors for hybrid search
├── qdrant/             # Qdrant client wrapper
│   └── client.ts       # Collection & search operations
├── prompts/            # Configurable prompt system
│   ├── types.ts        # Prompt configuration types
│   ├── loader.ts       # JSON config loader
│   └── template.ts     # Template rendering engine
└── index.ts            # Main entry point & MCP server setup
```

### **Key Components**

#### 1. **Main Entry Point** (`src/index.ts`)

- Initializes MCP server with stdio or HTTP transport
- Validates environment configuration
- Registers 8 MCP tools for vector operations
- Handles tool execution and error responses
- Supports configurable prompts for guided workflows

#### 2. **Embedding Providers** (`src/embeddings/`)

**Factory Pattern** for provider abstraction:

```typescript
interface EmbeddingProvider {
  embed(text: string): Promise<EmbeddingResult>;
  embedBatch(texts: string[]): Promise<EmbeddingResult[]>;
  getDimensions(): number;
  getModel(): string;
}
```

**Providers**:

- **Ollama** (default): Local, no API key, 768-1024 dims
- **OpenAI**: Cloud, 1536-3072 dims, 3500 req/min
- **Cohere**: Cloud, 1024 dims, multilingual, 100 req/min
- **Voyage**: Cloud, 1024-1536 dims, code-specialized, 300 req/min

**Features**:

- Rate limiting with exponential backoff
- Batch processing support
- Configurable retry logic
- Environment-based configuration

#### 3. **Qdrant Manager** (`src/qdrant/client.ts`)

Wrapper around Qdrant REST client:

- **Collection Management**: Create, list, delete, get info
- **Document Operations**: Add points (with/without sparse vectors)
- **Search**: Semantic search, hybrid search (RRF fusion)
- **ID Normalization**: Converts string IDs to UUID format
- **Hybrid Search**: Combines dense + sparse vectors for better results

#### 4. **Prompts System** (`src/prompts/`)

Configurable workflow templates:

- JSON-based prompt definitions
- Template variable substitution (`{{variable}}`)
- Required/optional arguments with defaults
- Examples: RAG setup, collection analysis, search comparison

---

## **MCP Tools (8 Total)**

### Collection Management

1. **`create_collection`** - Create vector collection with distance metric
2. **`list_collections`** - List all collections
3. **`get_collection_info`** - Get collection stats and config
4. **`delete_collection`** - Delete collection and documents

### Document Operations

5. **`add_documents`** - Add documents with auto-embedding
6. **`semantic_search`** - Natural language search with filters
7. **`hybrid_search`** - Semantic + keyword (BM25) search
8. **`delete_documents`** - Delete by ID

### Resources

- `qdrant://collections` - List collections
- `qdrant://collection/{name}` - Collection details

---

## **Key Patterns & Conventions**

### 1. **Factory Pattern**

`EmbeddingProviderFactory` creates providers from environment config:

```typescript
const embeddings = EmbeddingProviderFactory.createFromEnv();
```

### 2. **Strategy Pattern**

Different embedding providers implement same interface, swappable at runtime.

### 3. **Rate Limiting**

Bottleneck library handles API throttling with configurable limits per provider.

### 4. **Hybrid Search**

Combines dense (semantic) + sparse (BM25) vectors using Reciprocal Rank Fusion (RRF).

### 5. **Transport Modes**

- **stdio**: Local MCP server (default, for Claude Desktop)
- **http**: Remote server with Express (production deployments)

### 6. **Error Handling**

- Validates environment variables at startup
- Checks Ollama availability and model existence
- Returns structured error responses in MCP format

### 7. **Testing Strategy**

- **Unit Tests**: 376 tests for individual components
- **Functional Tests**: 46 end-to-end integration tests
- **Coverage**: 98%+ with strict thresholds
- **CI/CD**: GitHub Actions on Node 20 & 22

---

## **Configuration**

### Environment Variables

```bash
# Core
QDRANT_URL=http://localhost:6333
EMBEDDING_PROVIDER=ollama  # or openai, cohere, voyage

# Provider-specific
OPENAI_API_KEY=sk-...
COHERE_API_KEY=...
VOYAGE_API_KEY=...

# Customization
EMBEDDING_MODEL=nomic-embed-text
EMBEDDING_DIMENSIONS=768
EMBEDDING_MAX_REQUESTS_PER_MINUTE=1000
EMBEDDING_RETRY_ATTEMPTS=3

# Transport
TRANSPORT_MODE=stdio  # or http
HTTP_PORT=3000

# Prompts
PROMPTS_CONFIG_FILE=prompts.json
```

### Docker Services

```yaml
services:
  qdrant: # Vector database (ports 6333, 6334)
  ollama: # Local embeddings (port 11434)
```

---

## **Getting Started as a Developer**

### 1. **Setup**

```bash
npm install
docker compose up -d
docker exec ollama ollama pull nomic-embed-text
npm run build
```

### 2. **Development Workflow**

```bash
npm run dev          # Auto-reload development
npm test             # Run test suite
npm run type-check   # TypeScript validation
npm run build        # Production build
```

### 3. **Key Files to Understand**

- `src/index.ts` - MCP server setup and tool handlers
- `src/embeddings/factory.ts` - Provider initialization
- `src/qdrant/client.ts` - Vector database operations
- `.env.example` - Configuration reference

### 4. **Adding a New Tool**

1. Add tool definition in `ListToolsRequestSchema` handler
2. Add case in `CallToolRequestSchema` handler
3. Create Zod schema for validation
4. Implement logic using `qdrant` and `embeddings` clients
5. Add tests in `src/index.test.ts`

### 5. **Adding a New Provider**

1. Create `src/embeddings/your-provider.ts` implementing `EmbeddingProvider`
2. Add case in `factory.ts`
3. Add tests in `src/embeddings/your-provider.test.ts`
4. Update `.env.example` and README

### 6. **Testing**

```bash
npm test                    # All tests
npm run test:ui             # Interactive UI
npm run test:coverage       # Coverage report
npm run test:providers      # Provider verification
```

---

## **Critical Conventions**

✅ **ES Modules**: Use `.js` extensions in imports (TypeScript requirement)
✅ **Strict TypeScript**: All code must pass strict type checking
✅ **Conventional Commits**: `feat:`, `fix:`, `BREAKING CHANGE:` for semantic versioning
✅ **Test Coverage**: Maintain 98%+ coverage, add tests for new features
✅ **Code Style**: Biome enforces 2-space indent, double quotes, semicolons
✅ **Error Handling**: Return MCP-formatted errors with `isError: true`
✅ **Rate Limiting**: Configure per-provider limits to avoid API throttling

---

## **Deployment Modes**

### Local (stdio)

For Claude Desktop integration - server runs as subprocess.

### Remote (HTTP)

For production deployments - requires reverse proxy with HTTPS/auth.

---

This is a well-architected, production-ready MCP server with comprehensive testing, multiple provider support, and flexible deployment options. The codebase follows clean architecture principles with clear separation of concerns between embedding providers, vector operations, and MCP protocol handling.
