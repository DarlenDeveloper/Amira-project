import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import PageHeader from '../components/PageHeader.jsx';
import { useCollection, setDocById, formatDate } from '../db.js';

// Models offered to the admin. "lite" is the small, fast, low-cost default used
// for chat; the standard flash model is available for richer answers.
const MODELS = [
  { value: 'gemini-2.5-flash-lite', label: 'Gemini 2.5 Flash Lite (fast, default)' },
  { value: 'gemini-2.5-flash', label: 'Gemini 2.5 Flash (richer)' },
];

const DEFAULTS = {
  enabled: true,
  persona:
    'You are Amira Agent, the warm, knowledgeable assistant for Amira Interiors — a luxury East African interiors brand. Help customers explore finishes (wall panels, marble, stone, lighting and more), suggest ideas for their space, and guide them toward products and booking a consultation. Be concise, refined and friendly. Prices are in Ugandan shillings (UGX). If unsure, offer to connect them with the Amira team rather than inventing details.',
  greeting: 'Ask me anything about Amira collections, design ideas, or personalized recommendations',
  model: 'gemini-2.5-flash-lite',
  temperature: 0.7,
  suggestions: [
    'Help me design a living room',
    'What wall panels do you recommend?',
    'Show me luxury marble options',
  ],
};

export default function Agent() {
  // The config lives in a single doc: config/agent. Read the small `config`
  // collection and pick it out.
  const { data, loading } = useCollection('config');
  const saved = useMemo(() => data.find((d) => d.id === 'agent') ?? null, [data]);

  // Recent agent activity — most recently updated conversations.
  const { data: convData } = useCollection('conversations');
  const recent = useMemo(() => {
    return [...convData]
      .sort((a, b) => (b.updatedAt?.toMillis?.() ?? 0) - (a.updatedAt?.toMillis?.() ?? 0))
      .slice(0, 6);
  }, [convData]);

  const [form, setForm] = useState(DEFAULTS);
  const [hydrated, setHydrated] = useState(false);
  const [busy, setBusy] = useState(false);
  const [status, setStatus] = useState(''); // '' | 'saved' | error msg

  // Hydrate the form once from the saved doc (or defaults).
  useEffect(() => {
    if (hydrated || loading) return;
    if (saved) {
      setForm({
        enabled: saved.enabled !== false,
        persona: saved.persona ?? DEFAULTS.persona,
        greeting: saved.greeting ?? DEFAULTS.greeting,
        model: saved.model ?? DEFAULTS.model,
        temperature: typeof saved.temperature === 'number' ? saved.temperature : DEFAULTS.temperature,
        suggestions: Array.isArray(saved.suggestions) ? saved.suggestions : DEFAULTS.suggestions,
      });
    }
    setHydrated(true);
  }, [saved, loading, hydrated]);

  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));

  // The on/off switch persists immediately (a dedicated control shouldn't need
  // a separate Save). Optimistic update with revert on failure. A merge write
  // touches only `enabled`, leaving the rest of the config intact.
  const [toggling, setToggling] = useState(false);
  const toggleEnabled = async (next) => {
    setForm((f) => ({ ...f, enabled: next }));
    setToggling(true);
    setStatus('');
    try {
      await setDocById('config', 'agent', { enabled: next });
    } catch (err) {
      setForm((f) => ({ ...f, enabled: !next })); // revert
      setStatus(err.message ?? 'Could not update. Please try again.');
    } finally {
      setToggling(false);
    }
  };

  const save = async (e) => {
    e.preventDefault();
    setBusy(true);
    setStatus('');
    try {
      await setDocById('config', 'agent', {
        enabled: form.enabled,
        persona: form.persona.trim(),
        greeting: form.greeting.trim(),
        model: form.model,
        temperature: Number(form.temperature),
        suggestions: form.suggestions
          .map((s) => s.trim())
          .filter(Boolean)
          .slice(0, 6),
      });
      setStatus('saved');
      window.setTimeout(() => setStatus((s) => (s === 'saved' ? '' : s)), 2500);
    } catch (err) {
      setStatus(err.message ?? 'Could not save. Please try again.');
    } finally {
      setBusy(false);
    }
  };

  const suggestionsText = form.suggestions.join('\n');
  const onSuggestions = (e) =>
    setForm((f) => ({ ...f, suggestions: e.target.value.split('\n') }));

  return (
    <div className="page">
      <PageHeader
        eyebrow="AMIRA Agent"
        title="AI Agent"
        subtitle="Tune the in-app assistant — its voice, model, and suggested prompts."
        action={
          <span className={`agent-state-pill${form.enabled ? ' agent-state-pill--on' : ''}`}>
            {form.enabled ? 'Live' : 'Off'}
          </span>
        }
      />

      <div className="agent-layout">
        <form className="form agent-form" onSubmit={save}>
        {/* On / off — saves immediately */}
        <label className="agent-toggle">
          <input
            type="checkbox"
            checked={form.enabled}
            disabled={toggling}
            onChange={(e) => toggleEnabled(e.target.checked)}
          />
          <span>
            <strong>Agent enabled{toggling ? ' …' : ''}</strong>
            <em>
              {form.enabled
                ? 'The assistant is live in the app.'
                : 'The app shows the assistant as unavailable.'}
            </em>
          </span>
        </label>

        <label className="form-field">
          <span>Persona / system prompt</span>
          <textarea
            rows={6}
            value={form.persona}
            onChange={set('persona')}
            placeholder="Describe how the agent should speak and behave…"
          />
          <small className="field-hint">
            This is the agent's core instruction. It always knows the live product catalogue.
          </small>
        </label>

        <label className="form-field">
          <span>Welcome message</span>
          <input value={form.greeting} onChange={set('greeting')} placeholder="Shown on the agent's welcome screen" />
        </label>

        <div className="form-row">
          <label className="form-field">
            <span>Model</span>
            <select value={form.model} onChange={set('model')}>
              {MODELS.map((m) => (
                <option key={m.value} value={m.value}>{m.label}</option>
              ))}
            </select>
          </label>
          <label className="form-field">
            <span>Creativity ({Number(form.temperature).toFixed(1)})</span>
            <input
              type="range"
              min="0"
              max="1"
              step="0.1"
              value={form.temperature}
              onChange={set('temperature')}
            />
            <small className="field-hint">Lower = focused and factual · Higher = more creative.</small>
          </label>
        </div>

        <label className="form-field">
          <span>Suggested prompts (one per line)</span>
          <textarea
            rows={4}
            value={suggestionsText}
            onChange={onSuggestions}
            placeholder={'Help me design a living room\nWhat wall panels do you recommend?'}
          />
          <small className="field-hint">Shown as quick-tap chips in the app. Up to 6.</small>
        </label>

        <div className="agent-actions">
          <button type="submit" className="primary-btn" disabled={busy}>
            {busy ? 'Saving…' : 'Save changes'}
          </button>
          {status === 'saved' && <span className="agent-saved">✓ Saved</span>}
          {status && status !== 'saved' && <span className="form-error">{status}</span>}
        </div>
        </form>

        <aside className="agent-recent">
          <div className="agent-recent-head">
            <h2 className="agent-recent-title">Recent activity</h2>
            <Link to="/conversations" className="agent-recent-link">View all</Link>
          </div>

          {recent.length === 0 ? (
            <p className="agent-recent-empty">No conversations yet. Messages will appear here once members start chatting with the agent.</p>
          ) : (
            <ul className="agent-recent-list">
              {recent.map((c) => (
                <li key={c.id} className="agent-recent-item">
                  <div className="agent-recent-top">
                    <span className="agent-recent-name">{c.customer || 'Member'}</span>
                    <span className="agent-recent-time">{formatDate(c.updatedAt)}</span>
                  </div>
                  {c.lastUserMessage && (
                    <p className="agent-recent-q">“{c.lastUserMessage}”</p>
                  )}
                  {c.lastMessage && (
                    <p className="agent-recent-a">{c.lastMessage}</p>
                  )}
                </li>
              ))}
            </ul>
          )}
        </aside>
      </div>
    </div>
  );
}
