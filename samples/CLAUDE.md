## taru Knowledge Graph

You have access to the taru MCP server — a research knowledge graph with temporal knowledge management.

### Tools

- search_graph: Search knowledge base by English query
- read_full_document: Read full document content by UUID
- store_document: Store extracted knowledge (handles embedding + graph)
- list_documents: List all documents with status and confidence
- list_conflicts: View pending knowledge conflicts
- rebalance: Clean up the knowledge graph (merge keywords, remove orphans)

### Rules

1. **Always search before storing.** Before store_document, call search_graph with the core claim to check for conflicts.

2. **Document vs Opinion classification:**
   - doc_type="document": Objective, research-backed facts, data, verified information.
   - doc_type="opinion": Subjective insights, ideas, hypotheses, preferences, or conversational knowledge from humans.
   - When a user shares a personal view, idea, preference, or experience → opinion.
   - When referencing published research, official data, or verified facts → document.
   - Opinions get lower default confidence (0.50) than documents (0.85).
   - Store the original conversation/context in content field for traceability.

3. **Conflict resolution:**
   - supersedes_doc_id: Only when new info definitively invalidates old (retraction, correction). Marks old doc invalid.
   - disputes_doc_id: Legitimate disagreement (competing theories). Both remain valid. USE THIS FOR COMPETING SCIENTIFIC CLAIMS.
   - refines_doc_id: New info adds nuance to old. Both remain valid.
   - Do NOT default to superseding. Competing claims must coexist.

4. **Confidence scores:** 0.95 (meta-analysis) → 0.85 (peer-reviewed, default for documents) → 0.70 (preprint) → 0.50 (opinion, default) → 0.30 (unverified)

5. **Extraction in English.** All titles, core_claims, keywords must be English for embedding consistency. Keywords lowercase and specific.

6. **One claim per document.** Multiple independent claims from one source → separate store_document calls.

7. **Source traceability.** Always set source_file: web://url, file://name, mcp://topic, or conversation://context. Set valid_from to current time for opinions.

8. **Capturing conversational knowledge:**
   - When a user expresses an opinion or idea during conversation, store it proactively.
   - Include the full conversational context in the content field.
   - Use source_file="conversation://session" to mark conversational origins.
   - Extract the core insight as core_claim, even if the user expressed it casually.

9. **Search result interpretation:**
   - disputed_by present → present both perspectives
   - confidence → note reliability level
   - valid_until set → superseded, prefer newer but note history
   - doc_type=opinion → present as "team insight" not "established fact"

10. **Maintenance.** Run list_conflicts after bulk ingestion. Run rebalance after storing many documents.
