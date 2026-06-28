import { useEffect, useMemo, useState } from 'react';
import PageHeader from '../components/PageHeader.jsx';
import StatusBadge from '../components/StatusBadge.jsx';
import {
  useCollection,
  usePaginatedCollection,
  formatDate,
  formatDateTime,
  updateDocById,
  interveneConversation,
  sendAdminMessage,
} from '../db.js';

const initials = (name) =>
  (name || '?')
    .split(' ')
    .slice(0, 2)
    .map((n) => n[0])
    .join('')
    .toUpperCase();

const msgTime = (t) => (t?.toDate ? formatDateTime(t) : (t || ''));

function isPhoneCredentialEmail(email) {
  return String(email || '').includes('@phone.amira.app');
}

/** Name, phone, and email for a conversation thread. */
function resolveContact(convo, userByUid) {
  const profile = userByUid[convo.uid];
  let phone = String(convo.phone || profile?.phone || '').trim();
  let email = String(convo.email || '').trim();

  if (!phone && email && !email.includes('@')) {
    phone = email;
    email = String(profile?.email || '').trim();
  }
  if (isPhoneCredentialEmail(email)) {
    email = String(profile?.email || '').trim();
    if (isPhoneCredentialEmail(email)) email = '';
  }
  if (!email && profile?.email && !isPhoneCredentialEmail(profile.email)) {
    email = String(profile.email).trim();
  }

  let name = String(convo.customer || profile?.name || '').trim();
  if (!name || name === 'Amira Member') {
    name =
      String(profile?.name || '').trim() ||
      phone ||
      (email ? email.split('@')[0] : '') ||
      'Amira Member';
  }

  const contactParts = [phone, email].filter(Boolean);
  const contactLine = contactParts.length ? contactParts.join(' · ') : '—';

  return { name, phone, email, contactLine };
}

export default function Conversations() {
  const { data, loading, hasMore, loadMore } = usePaginatedCollection('conversations', {
    orderByField: 'updatedAt',
    orderDir: 'desc',
    pageSize: 50,
  });

  const { data: users } = useCollection('users');

  const userByUid = useMemo(
    () => Object.fromEntries(users.map((u) => [u.id, u])),
    [users],
  );

  const conversations = data;

  const [activeId, setActiveId] = useState(null);
  useEffect(() => {
    if (!activeId && conversations.length) setActiveId(conversations[0].id);
  }, [conversations, activeId]);

  const active = conversations.find((c) => c.id === activeId);
  const activeContact = active ? resolveContact(active, userByUid) : null;

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

  // The conversation list is a one-shot paginated fetch (not live), so a
  // `mode: 'human'` write won't flow back into `active`. Track takeovers
  // locally so the banner + composer appear immediately.
  const [intervenedIds, setIntervenedIds] = useState(() => new Set());
  const intervened =
    active?.mode === 'human' || (!!activeId && intervenedIds.has(activeId));

  const resolve = async (id) => {
    await updateDocById('conversations', id, { status: 'resolved' });
  };

  // Take over the thread from the AI. Once intervened it's customer ↔ admin.
  const [intervening, setIntervening] = useState(false);
  const takeOver = async (id) => {
    setIntervening(true);
    try {
      await interveneConversation(id);
      setIntervenedIds((prev) => new Set(prev).add(id));
    } finally {
      setIntervening(false);
    }
  };

  // Admin reply composer (only shown once a thread is intervened).
  const [draft, setDraft] = useState('');
  const [sending, setSending] = useState(false);
  // Clear the draft when switching threads.
  useEffect(() => {
    setDraft('');
  }, [activeId]);

  const sendReply = async () => {
    const text = draft.trim();
    if (!text || sending || !activeId) return;
    setSending(true);
    try {
      await sendAdminMessage(activeId, text);
      setDraft('');
    } finally {
      setSending(false);
    }
  };

  const onComposerKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendReply();
    }
  };

  return (
    <div className="page">
      <PageHeader
        eyebrow="AMIRA Agent"
        title="Conversations"
        subtitle={`${conversations.length} threads · ${openCount} open`}
      />

      <div className="convo-layout">
        <div className="convo-list">
          {conversations.map((c) => {
            const { name, contactLine } = resolveContact(c, userByUid);
            return (
              <button
                key={c.id}
                type="button"
                className={`convo-item${c.id === activeId ? ' convo-item--active' : ''}`}
                onClick={() => setActiveId(c.id)}
              >
                <span className="avatar">{initials(name)}</span>
                <span className="convo-meta">
                  <span className="convo-top">
                    <span className="cell-strong">{name}</span>
                    <span className="convo-time">{formatDate(c.updatedAt)}</span>
                  </span>
                  <span className="convo-contact">{contactLine}</span>
                  <span className="convo-preview">
                    {c.lastMessage || 'No messages yet'}
                    {c.productName ? ` · ${c.productName}` : ''}
                  </span>
                </span>
              </button>
            );
          })}
          {hasMore && !loading && (
            <button type="button" className="ghost-btn" onClick={loadMore} style={{ margin: 12 }}>
              Load more
            </button>
          )}
        </div>

        <div className="convo-thread">
          {active && activeContact ? (
            <>
              <div className="thread-header">
                <div>
                  <div className="cell-strong">{activeContact.name}</div>
                  <div className="cell-sub">{activeContact.contactLine}</div>
                  {active.productName && (
                    <span className="agent-state-pill" style={{ marginTop: 6 }}>
                      {active.productName}
                    </span>
                  )}
                </div>
                <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                  <StatusBadge status={active.status} />
                  {!intervened && (
                    <button
                      type="button"
                      className="ghost-btn"
                      onClick={() => takeOver(active.id)}
                      disabled={intervening}
                    >
                      {intervening ? 'Taking over…' : 'Intervene'}
                    </button>
                  )}
                  {active.status === 'open' && (
                    <button type="button" className="ghost-btn" onClick={() => resolve(active.id)}>
                      Resolve
                    </button>
                  )}
                </div>
              </div>
              <div className="thread-body">
                {intervened && (
                  <div className="intervene-banner">
                    You've taken over this conversation — the AI assistant is paused.
                  </div>
                )}
                {orderedMessages.map((m) => {
                  // System notices (e.g. "agent unavailable") aren't from the
                  // customer or the AI — show them as a centered notice.
                  if (m.from === 'system') {
                    return (
                      <div key={m.id} className="bubble-row from-system">
                        <div className="bubble bubble--system">{m.text}</div>
                        <span className="bubble-time">{msgTime(m.time)}</span>
                      </div>
                    );
                  }
                  const isUser = m.from === 'user';
                  const isAdmin = m.from === 'admin';
                  return (
                    <div
                      key={m.id}
                      className={`bubble-row ${isUser ? 'from-user' : 'from-agent'}`}
                    >
                      <div
                        className={`bubble ${
                          isUser ? 'bubble--user' : isAdmin ? 'bubble--admin' : 'bubble--agent'
                        }${m.status === 'error' ? ' bubble--error' : ''}`}
                      >
                        {isAdmin && <span className="bubble-sender">You · Amira team</span>}
                        {m.imageUrl && (
                          <a
                            href={m.imageUrl}
                            target="_blank"
                            rel="noreferrer"
                            className="bubble-image"
                          >
                            <img src={m.imageUrl} alt="Attachment" loading="lazy" />
                          </a>
                        )}
                        {m.text && <span className="bubble-text">{m.text}</span>}
                        {m.source && isUser && (
                          <span className="bubble-meta"> · {m.source}</span>
                        )}
                      </div>
                      <span className="bubble-time">{msgTime(m.time)}</span>
                    </div>
                  );
                })}
              </div>
              {intervened && (
                <div className="thread-composer">
                  <textarea
                    rows={1}
                    value={draft}
                    onChange={(e) => setDraft(e.target.value)}
                    onKeyDown={onComposerKeyDown}
                    placeholder="Reply as the Amira team…"
                  />
                  <button
                    type="button"
                    className="primary-btn"
                    onClick={sendReply}
                    disabled={sending || !draft.trim()}
                  >
                    {sending ? 'Sending…' : 'Send'}
                  </button>
                </div>
              )}
            </>
          ) : (
            <p className="empty">Select a conversation</p>
          )}
        </div>
      </div>
    </div>
  );
}
