# Object-Oriented Programming (OOP) Patterns

1. Favor Composition Over Inheritance

When to apply: Modeling behaviors that may vary independently over time.Patterns: Strategy, Bridge. Explanation: Strategy encapsulates interchangeable algorithms behind a common interface; Bridge decouples abstractions from implementations to allow independent variation.Do: Compose objects via constructor injection.

```ts
class Engine {}
class Car {
  constructor(private engine: Engine) {}
}
```

Don't: Extend classes for behavior reuse.

2. Dependency Injection (DI)

When to apply: Service layers, repositories, external integrations.Patterns: Service Locator (avoid), DI Container. Explanation: DI Container centralizes object creation and injection; Service Locator offers a registry for dependencies but leads to hidden coupling.Do: Inject typed interfaces rather than new.

```ts
class UserService {
  constructor(private repo: UserRepository) {}
}
```

Don't: Hardcode dependencies inside classes.

3. Tell, Don’t Ask

When to apply: Encapsulated domain logic.Patterns: Command, Method Invocation. Explanation: Command encapsulates actions as objects enabling undo/redo; Method Invocation treats method calls as explicit instructions.Do: Call behavior methods.

```ts
order.complete();
```

Don't: Inspect internals then mutate externally.

4. Law of Demeter

When to apply: Any object collaboration.Patterns: N/A. Explanation: Law of Demeter is a design guideline advising minimal coupling by limiting method calls to immediate collaborators.Do: Use only immediate collaborators.

```ts
user.changeEmail(newEmail);
```

Don't: Chain deep property/method calls.

5. Make Impossible States Impossible

When to apply: State machines, config objects.Patterns: Discriminated Unions. Explanation: TypeScript feature modeling a set of exclusive states via tagged unions, ensuring compile-time validity.Do: Encode valid states in types.

```ts
type Loading = { status: "loading" };
type Loaded<T> = { status: "loaded"; data: T };
```

Don't: Validate core states only at runtime.

6. Combat Primitive Obsession

When to apply: Domain value objects.Patterns: Value Object. Explanation: Encapsulates simple domain concepts in immutable classes with built-in validation.Do: Wrap primitives in classes with validation.

```ts
class Email {
  constructor(public readonly value: string) {
    if (!value.includes("@")) throw new Error("Invalid email");
  }
}
```

Don't: Pass raw strings or numbers around.

7. Replace Conditionals with Polymorphism

When to apply: Varying algorithms/behaviors.Patterns: Strategy. Explanation: Defines a family of interchangeable algorithms, encapsulating each in its own class behind a common interface.Do: Define interfaces and inject implementations.

```ts
interface PaymentStrategy {
  pay(amount: number): void;
}
```

Don't: Use if/else chains or switch for behavior.

8. Liskov Substitution Principle (LSP)

When to apply: Subtype creation.Patterns: Inheritance. Explanation: Establishes is-a relationships, allowing subclasses to reuse and extend base class behavior.Do: Ensure derived classes honor base contracts.

Don't: Change postconditions or omit base behavior.

9. Interface Segregation Principle (ISP)

When to apply: Public API design.Patterns: Interface Abstraction. Explanation: Segregates broad interfaces into smaller, focused ones to reduce unnecessary dependencies.Do: Create small, focused interfaces.

Don't: Force extra methods on implementers.

10. Dependency Inversion Principle (DIP)

When to apply: Module boundary design.Patterns: Abstraction Layer. Explanation: Introduces interfaces or abstract classes between modules, inverting dependencies to decouple high- and low-level components.Do: Depend on interfaces, not implementations.

Don't: Import concrete classes in high-level modules.

11. Fail Fast & Guards

When to apply: Input validation and invariants.Patterns: Guard Clause. Explanation: Early-exit checks at the start of functions to validate inputs and enforce invariants promptly.Do: Use centralized guards for preconditions.

```ts
function assertEmail(email: string): asserts email is string {
  if (!email.includes("@")) throw new Error("Invalid email");
}
```

Don't: Let invalid data flow silently.

12. Observers & Events

When to apply: Cross-object notifications.Patterns: Observer, Event Emitter. Explanation: Observer defines a publisher-subscriber model for change notifications; Event Emitter provides a simple API to register and trigger event handlers.Do: Decouple publishers and subscribers.

```ts
class EventEmitter<T> { /_ subscribe/publish API _/ }
```

Don't: Directly call listener logic in source classes.

Global Heuristics & Edge Cases

Inheritance vs. Composition: Use inheritance only for true is-a relationships.

Controlled Querying: Permit minimal getters when necessary, but encapsulate decisions in methods.

Pragmatism: If strict adherence impairs clarity, annotate exceptions with comments explaining rationale.
