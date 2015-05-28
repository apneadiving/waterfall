Waterfall
=========
#### Goal

Be able to chain ruby commands, and treat them like a flow.

#### Rationale
Coding is all about writing a flow of commands.

Generally you basically go on, unless something wrong happens. Whenever this happens you have to halt the flow and send feedback to the user.

When conditions stack up, readability decreases. One way to solve it is to create abstractions (service objects or the like). There some questions arise:
* what should a good service return?
* how to handle errors?
* how to call a service within a service?
* how to chain services / commands

Those topics are discussed in [the slides here](https://slides.com/apneadiving/service-objects-waterfall-rails/live) to explain service objects and compare libraries.

Check the [wiki for details](https://github.com/apneadiving/waterfall/wiki).

Thanks
=========
Huge thanks to [laxrph10](https://github.com/laxrph10) for the help during infinite naming brainstorming.
