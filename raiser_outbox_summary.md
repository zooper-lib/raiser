# raiser outbox summary

## Goal

Implement a `raiser` ecosystem extension for **durable event delivery** using an **outbox pattern**.

The purpose is to allow apps using `raiser` to persist emitted events so they survive:

- app crashes
- app restarts
- offline periods
- temporary handler failures

This is **not** meant to be a completely separate unrelated messaging framework. It is a **`raiser`-related package family** built specifically around `raiser` events and publishing abstractions.

---

## Core architectural decision

This should **not** be built directly into `raiser` core.

Instead:

- `raiser` remains the **in-process event publishing package**
- the durable outbox becomes a **separate but related package**
- storage-specific implementations live in additional subpackages

Recommended package family:

- `raiser`
- `raiser_outbox`
- `raiser_outbox_sembast`
- `raiser_outbox_drift`

The outbox should stay clearly under the `raiser` umbrella rather than using a completely unrelated name, because it extends `raiser` semantics with durability.

---

## Critical usability requirement

A user must be able to start with plain `raiser` **without persistence**, and later add durable delivery **without changing much application code**.

That means persistence must be **opt-in by decoration or implementation swap**, not by introducing a different publish API.

### Required design consequence

Application code should keep calling the same publish contract from day one.

Example:

```dart
await eventPublisher.publish(orderCreatedEvent);
```

This call site must remain unchanged whether the app uses:

- only in-memory publishing
- outbox persistence plus immediate dispatch
- outbox persistence plus deferred dispatch

The user should enable durability mainly by wiring a different implementation through dependency injection or configuration.

---

## Conceptual model

We are **not** implementing blind handler replay.

We are implementing a **durable outbox**.

That means:

1. application/domain code emits an event
2. the event is stored durably
3. a dispatcher later delivers pending events
4. if the app crashes before delivery, the event still exists
5. after restart, delivery can continue

This is inspired by reliable message delivery / outbox ideas like those used in systems such as MassTransit, but adapted for Flutter/local-app architecture.

---

## What `raiser` should remain responsible for

`raiser` should continue to focus on:

- event publishing abstractions
- event subscriptions / handlers
- event bus behavior
- event envelopes and metadata foundations
- in-process dispatch semantics
- extension points that allow later decoration

`raiser` should **not** directly take responsibility for:

- persistence
- retries
- crash recovery
- deduplication
- outbox scheduling
- storage backend concerns

The core package should stay lightweight and usable on its own.

---

## What `raiser_outbox` should implement

`raiser_outbox` should provide durable delivery on top of `raiser`.

Main responsibilities:

- persist emitted events into an outbox store
- track delivery state
- dispatch pending events later
- support retries
- support crash recovery
- support replay of pending undelivered events
- support idempotency / deduplication hooks
- optionally support ordered delivery where needed

---

## Main API design principle

Do **not** introduce a separate infrastructure-facing publish API such as:

- `publishDurably(...)`
- `publishWithOutbox(...)`
- `storeAndPublish(...)`

That would leak infrastructure concerns into application code and make migration painful.

Instead, keep a single stable publishing abstraction in `raiser`, for example something like:

- `EventPublisher`
- `DomainEventPublisher`
- `EventBus`

Then let `raiser_outbox` provide an implementation or decorator of that same contract.

---

## Required migration behavior

The design must support this workflow:

### Phase 1: no persistence

The user wires a normal in-memory publisher.

### Phase 2: persistence needed later

The user swaps the publisher implementation to an outbox-aware version and keeps the same application call sites.

So the migration path should mainly be:

- install `raiser_outbox`
- configure an outbox store
- replace publisher registration in DI
- optionally start an outbox dispatcher

The application layer, use cases, services, and other publishing call sites should remain largely unchanged.

---

## Recommended implementation style

`raiser_outbox` should either:

- implement the same publisher abstraction as `raiser`
- or decorate / wrap the existing in-memory publisher

Typical shape:

- `InMemoryEventPublisher` in `raiser`
- `OutboxEventPublisher` in `raiser_outbox`

The outbox publisher should be able to compose with the in-memory publisher rather than forcing a whole different programming model.

---

## Useful behavior modes

The outbox-aware publisher should ideally support configurable modes such as:

- **in-memory only**
  - dispatch directly without persistence

- **persist then dispatch**
  - store the event, then dispatch immediately

- **persist only**
  - store the event now and dispatch later through a background / startup dispatcher

- **persist then try dispatch**
  - store first, try immediate dispatch, leave pending for retry if dispatch fails

This provides flexibility without changing application code.

---

## Event metadata needed

The event or envelope model should include stable metadata that makes durable delivery possible.

Needed metadata includes:

- `eventId`
- `occurredAt`
- `eventType`
- `aggregateId` if available
- `aggregateVersion` or sequence if available
- serialized payload
- optional correlation metadata later
- optional causation metadata later

The `raiser` core should provide enough metadata foundations so `raiser_outbox` can integrate cleanly.

---

## Persisted outbox record model

A durable outbox record should roughly contain:

- unique outbox record id
- event id
- event type
- serialized event payload
- metadata
- created timestamp
- delivery status
- attempt count
- last attempt timestamp
- last error
- dispatched timestamp when successful

Possible delivery states:

- pending
- processing
- dispatched
- failed
- dead-lettered later if needed

---

## Main components to build

### `OutboxStore`

Abstraction for persisting and loading outbox records.

Responsibilities:

- add pending event
- fetch pending events
- mark as processing
- mark as dispatched
- mark as failed
- increment attempt count
- optionally archive or clean up old dispatched items

### `PersistedEventEnvelope`

A durable storage-friendly version of a `raiser` event envelope.

Responsibilities:

- contain serialized event plus metadata
- be easy to store
- be reconstructable back into a dispatchable event

### `OutboxDispatcher`

Reads pending items from the store and dispatches them through `raiser`.

Responsibilities:

- load pending events
- deserialize them
- publish them through the configured publisher / bus
- update outbox state depending on success or failure
- continue safely after crashes or app restarts

### Retry policy abstraction

Controls retry behavior.

Examples:

- max attempts
- retry delays
- backoff strategy
- permanent failure handling
- dead-letter policy later

### Idempotency / deduplication hooks

Needed because durable systems may redeliver.

This may be implemented through:

- handler-level deduplication
- processed event tracking
- pluggable delivery guards

---

## Behavioral assumptions

The design must assume:

- handlers can fail
- delivery may happen more than once
- retries may be necessary
- pending events must survive crashes
- durable handlers should be idempotent
- replay for durable delivery is not the same as synchronous in-memory publish semantics

---

## Storage package strategy

The core `raiser_outbox` package should stay storage-agnostic.

Concrete backends should live in separate packages, for example:

- `raiser_outbox_sembast`
- `raiser_outbox_drift`

This avoids forcing storage dependencies into the core package and keeps the ecosystem modular.

---

## Non-goals

At this stage, do **not** turn this into:

- a full external message broker
- a completely generic unrelated messaging platform
- a separate event model disconnected from `raiser`
- a workflow engine
- blind replay of all handlers as if normal in-memory publishing simply resumed
- a design that forces users to rewrite all publish call sites when they enable persistence

---

## Final design target

Design `raiser` so durable delivery is an optional infrastructure concern that can be enabled later by replacing or decorating the existing event publisher implementation, while keeping the public publish API and most application call sites unchanged.

Build the durability layer as a related package family under the `raiser` ecosystem:

- `raiser`
- `raiser_outbox`
- `raiser_outbox_sembast`
- `raiser_outbox_drift`

The result should let users:

- start with plain in-memory `raiser`
- add persistence later with minimal changes
- survive crashes and restarts
- continue dispatching pending events after recovery
- keep the core `raiser` package clean and focused

