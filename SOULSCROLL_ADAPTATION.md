# SoulScroll Adaptation Contract

This branch is a non-commercial evaluation adaptation of the upstream RunPod Fish Speech worker. It keeps the upstream default branch unchanged and records the requirements for a provider-neutral narration edition pipeline.

## Non-Commercial Scope

The upstream wrapper is MIT, but Fish model and weight rights are separate. No use of this branch implies commercial permission to host, distribute, or monetize the Fish model, generated audio, or voice-cloning capability.

## Required Hardening Before Any Public Use

1. Pin the upstream source commit, base-image digest, Fish model revision, and all runtime dependencies.
2. Use a chapter-level job with a canonical script, `edition_key`, `chapter_id`, locale, voice-profile revision, and synthesis-profile revision.
3. Enforce request size, job duration, output size, and retry limits. Do not accept arbitrary unbounded book text.
4. Move generated audio to object storage and return an artifact reference; do not use base64 endpoint responses as the persisted edition format.
5. Produce a separate timing manifest through forced alignment with stable sentence identifiers.
6. Require explicit voice-consent provenance before accepting any reference audio. Do not persist supplied reference clips by default.
7. Keep endpoint credentials, object-store credentials, and provider secrets outside Git and restrict the endpoint to the orchestration service.

## Portable Edition Contract

A SoulScroll client consumes only continuous chapter audio plus a timing manifest keyed by `edition_key`. It must never depend on Fish, RunPod, a provider-specific endpoint, or a provider-specific URL in reading state.

## Upstream Relationship

`upstream` remains `mguinhos/runpod-worker-fish-speech`. Pull upstream changes deliberately and review them before merge; never track a moving image tag or unpinned model revision in a deployed endpoint.
