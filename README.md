Waterfall
=========
#### Goal

Be able to chain ruby commands, and treat them like a flow.

#### Rationale
Coding is all about writing a flow of commands.

Generally you basically go on, unless something wrong happens. Whenever this happens you have to halt the flow and send feedback to the user.

When conditions stack up, readability decreases. One way to solve it is to create abstractions (service objects or the like). Some gems suggest a nice approach like [light service](https://github.com/adomokos/light-service) and [interactor](https://github.com/collectiveidea/interactor).

I like these approaches, but I dont like to have to write a class each time I need to chain services. Or I even dont want to create a class each time I need to chain something. My take on this was to create `waterfall`.

[Here are some slides](https://slides.com/apneadiving/service-objects-waterfall-rails/live) to explain service objects and compare libraries.

[Check the wiki for details](https://github.com/apneadiving/waterfall/wiki).

Thanks
=========
Huge thanks to [laxrph10](https://github.com/laxrph10) for the help during infinite naming brainstorming.
