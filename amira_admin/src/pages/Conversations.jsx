import { useEffect, useMemo, useState } from 'react';
import PageHeader from '../components/PageHeader.jsx';
import StatusBadge from '../components/StatusBadge.jsx';
import { useCollection, formatDate } from '../db.js';

const initials = (name) =>
  (name || '?')
    .split(' ')
    .slice(0, 2)
    .map((n) => n[0])
    .join('')
    .toUpperCase();

// Messages store `time` as a Firestore Timestamp; fall back to a string.
const msgTime = (t) => (t?.toDate ? formatDate(t) : (t || ''));

export default function Conversations() {
  const { data } = useCollection('conversations');

  const conversations = useMemo(() => {
    return [...data].sort((a, b) => {
      const at = a.updatedAt?.toMillis?.() ?? 0;
      const bt = b.updatedAt?.toMillis?.() ?? 0;
      return bt - at;
    });
  }, [data]);

  const [activeId, setActiveId] = useState(null);
  useEffect(() => {
    if (!activeId && conversations.length) setActiveId(conversations[0].id);
  }, [conversations, activeId]);

  const active = conversations.find((c) => c.id === activeId);
  const { data: messages } = useCollection(
    activeId ? `conversations/${activeId}/messages` : null,
  );
  const orderedMessages = useMemo(() => {
    return [...messages].sort((a, b) => {
      const at = a.time?.toMillis?.() ?? 0;
      const bt = b.time?.toMillis?.() ?? 0;
      return at - bt;
    });
  }, [messages]);

  const openCount = conversations.filter((c) => c.status === 'open').length;

  return (
    <div className="page">
      <PageHeader
        eyebrow="AMIRA Agent"
        title="Conversations"
        subtitle={`${conversations.length} threads · ${openCount} open`}
      />

      <div className="convo-layout">
        {/* Thread list */}
        <div className="convo-list">
          {conversations.map((c) => (
            <button
              key={c.id}
              type="button"
              className={`convo-item${c.id === activeId ? ' convo-item--active' : ''}`}
              onClick={() => setActiveId(c.id)}
            >
              <span className="avatar">{initials(c.customer)}</span>
              <span className="convo-meta">
                <span className="convo-top">
                  <span className="cell-strong">{c.customer}</span>
                  <span className="convo-time">{formatDate(c.updatedAt)}</span>
                </span>
                <span className="convo-preview">{c.email}</span>
              </span>
            </button>
          ))}
        </div>

        {/* Active thread */}
        <div className="convo-thread">
          {active ? (
            <>
              <div className="thread-header">
                <div>
                  <div className="cell-strong">{active.customer}</div>
                  <div className="cell-sub">{active.email}</div>
                </div>
                <StatusBadge status={active.status} />
              </div>
              <div className="thread-body">
                {orderedMessages.map((m) => (
                  <div key={m.id} className={`bubble-row ${m.from === 'user' ? 'from-user' : 'from-agent'}`}>
                    <div className={`bubble ${m.from === 'user' ? 'bubble--user' : 'bubble--agent'}`}>
                      {m.text}
                    </div>
                    <span className="bubble-time">{msgTime(m.time)}</span>
                  </div>
                ))}
              </div>
            </>
          ) : (
            <p className="empty">Select a conversation</p>
          )}
        </div>
      </div>
    </div>
  );
}
