# Stopwatch design note

Replace this template with a concise explanation before packaging the final project.

## Acknowledgement

Explain when timer and GPIO pending state is cleared and why an event cannot be acknowledged twice.

## Shared state

Explain which state is changed by each short handler and which work remains outside the event-capture boundary.

## Simultaneous events

Explain the chosen button-before-timer order and what happens when pause and tick arrive together.

