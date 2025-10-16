// https://github.com/berstend/puppeteer-extra/blob/c44c8bb0224c6bba2554017bfb9d7a1d0119f92f/packages/puppeteer-extra-plugin-stealth/evasions/navigator.permissions/index.js

() => {
  const isSecure = document.location.protocol.startsWith("https");

  // In headful on secure origins the permission should be "default", not "denied"
  if (isSecure) {
    utils.replaceGetterWithProxy(Notification, "permission", {
      apply() {
        return "default";
      },
    });
  }

  // Another weird behavior:
  // On insecure origins in headful the state is "denied",
  // whereas in headless it's "prompt"
  if (!isSecure) {
    const handler = {
      apply(target, ctx, args) {
        const param = (args || [])[0];

        const isNotifications =
          param && param.name && param.name === "notifications";
        if (!isNotifications) {
          return utils.cache.Reflect.apply(...arguments);
        }

        return Promise.resolve(
          Object.setPrototypeOf(
            {
              state: "denied",
              onchange: null,
            },
            PermissionStatus.prototype
          )
        );
      },
    };
    // Note: Don't use `Object.getPrototypeOf` here
    utils.replaceWithProxy(Permissions.prototype, "query", handler);
  }
}
