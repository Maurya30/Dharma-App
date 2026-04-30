# Dharma

**Krishna AI — scripture-grounded spiritual guidance for the Hindu diaspora.**

Dharma makes Hindu philosophy and scripture accessible to the diaspora generation. 
At its core is Krishna — an AI guide powered by Claude Haiku and grounded in 2,408 
verses from the Bhagavad Gita, Upanishads, and Rig Veda. Ask him anything. He 
remembers your past conversations, knows your goals, and responds with 
scripture-backed wisdom rooted in the actual texts.

> 🕉️ Coming to the App Store soon.

---

## Screenshots

<div align="center">
  <img src="Apple iPhone 16 Pro Max Screenshot 1.png" width="30%" />
  <img src="Apple iPhone 16 Pro Max Screenshot 2.png" width="30%" />
  <img src="Apple iPhone 16 Pro Max Screenshot 3.png" width="30%" />
</div>

---

## Technical Highlights

**Production RAG Pipeline**
2,408 Hindu scripture verses indexed with OpenAI text-embedding-3-small 
and stored in Supabase PostgreSQL with pgvector. Cosine similarity search 
runs via a custom Supabase SQL RPC function — returning semantically 
relevant scripture with zero keyword overlap required. A query about anxiety 
surfaces verses on non-attachment without the word anxiety appearing anywhere 
in the text.

**Multi-layer Context Engineering**
Every Krishna response is assembled from a dynamic system prompt containing 
the user's goals, active verse context, RAG-retrieved scripture, and a 
cross-session memory summary. A sliding window conversation manager keeps 
token counts bounded at any session length — full history under 6 messages, 
last 4 turns plus extractive summary beyond that. Anthropic prompt caching 
on the system prompt cuts token costs ~40% on repeated sends.

**Cross-session AI Memory**
After each conversation, a background POST to `/krishna/summarize-offering` 
generates a 2-3 sentence Haiku summary of what was discussed. This is written 
to Supabase as `last_offering_summary` and injected into the next session's 
system prompt as "Recent offering context" — giving Krishna genuine continuity 
across days without storing or transmitting raw conversation history.

**Zero-shot Behavioral Classification**
Krishna self-classifies each incoming message as factual, emotional/dilemma, 
or reflective via natural language instruction in the system prompt — adjusting 
response length, tone, and structure with zero additional latency or API cost. 
Factual questions get concise responses. Emotional questions get full 
scripture-grounded guidance. Reflection mode produces intimate, personal replies.

**Real-time SSE Streaming**
Custom Server-Sent Events implementation on a Vercel serverless backend — 
chunked transfer encoding, keepalive handling, graceful [DONE] termination. 
Sub-100ms first-token latency. Responses stream word by word to the iOS client 
as Claude generates them.

**Cost**
Under $0.001 per active user per day at current token volumes using 
Claude Haiku with prompt caching.

---

## Architecture



## Author

**Maurya Panchal** · University of Waterloo  
[m25panch@uwaterloo.ca](mailto:m25panch@uwaterloo.ca)  
[github.com/Maurya30](https://github.com/Maurya30)
