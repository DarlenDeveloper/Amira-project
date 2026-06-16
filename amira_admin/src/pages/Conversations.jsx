import { useState } from 'react';
import PageHeader from '../components/PageHeader.jsx';
import StatusBadge from '../components/StatusBadge.jsx';
import { conversations } from '../data/conversations.js';

const initials = (name) =>
  name.split(' ').slice(0, 2).map((n) => n[0]).join('').toUpperCase();

export default function Conversations() {
  const [activeId, setActiveId] = useState(conversations[0]?.id);
  const active = conversations.find((c) => c.id === activeId);
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
          {conversations.map((c) => {
            const last = c.messages[c.messages.length - 1];
            return (
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
                    <span className="convo-time">{c.updated}</span>
                  </span>
                  <span className="convo-preview">{last?.text}</span>
                </span>
              </button>
            );
          })}
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
                {active.messages.map((m, i) => (
                  <div key={i} className={`bubble-row ${m.from === 'user' ? 'from-user' : 'from-agent'}`}>
                    <div className={`bubble ${m.from === 'user' ? 'bubble--user' : 'bubble--agent'}`}>
                      {m.text}
                    </div>
                    <span className="bubble-time">{m.time}</span>
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
