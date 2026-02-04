<script>
import SnackbarContainer from './components/SnackBar/Container.vue';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { setColorTheme } from 'dashboard/helper/themeHelper'; // or correct relative path used there

export default {
  components: { SnackbarContainer },
  data() {
    return { theme: 'light' };
  },
  mounted() {
    this.forceDarkTheme();
    this.setLocale('es'); // ✅ force Spanish
    // this.listenToThemeChanges();
  },
  methods: {
    // ✅ NEW: force + persist dark mode everywhere (Chrome/Firefox/etc.)
    forceDarkTheme() {
      // Persist preference so Chatwoot never treats it as "auto"
      LocalStorage.set(LOCAL_STORAGE_KEYS.COLOR_SCHEME, 'dark');

      // Apply using the shared helper (adds body.dark + sets color-scheme)
      setColorTheme(true);

      // Also keep v3's existing class behavior consistent
      this.theme = 'dark';
      document.documentElement.classList.add('dark');
      document.body.classList.add('dark');
      document.documentElement.style.setProperty('color-scheme', 'dark');
    },

    // (Optional) keep this if you want OS to change theme automatically.
    // If you want forced dark always, leave it unused.
    listenToThemeChanges() {
      const mql = window.matchMedia('(prefers-color-scheme: dark)');
      mql.onchange = () => {
        // If you still want to keep forced dark, just re-apply:
        this.forceDarkTheme();
      };
    },
    setLocale(locale = 'es') {
      // ✅ default to Spanish even if called without arg
      this.$root.$i18n.locale = locale;
    },
  },
};
</script>

<template>
  <div class="h-full min-h-screen w-full antialiased" :class="theme">
    <router-view />
    <SnackbarContainer />
  </div>
</template>

<style lang="scss">
@tailwind base;
@tailwind components;
@tailwind utilities;

@import '../dashboard/assets/scss/next-colors';

html,
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto,
    Oxygen-Sans, Ubuntu, Cantarell, 'Helvetica Neue', sans-serif;
  @apply h-full w-full;

  input,
  select {
    outline: none;
  }
}

.text-link {
  @apply text-n-brand font-medium hover:text-n-blue-10;
}

.v-popper--theme-tooltip .v-popper__inner {
  background: black !important;
  font-size: 0.75rem;
  padding: 4px 8px !important;
  border-radius: 6px;
  font-weight: 400;
}

.v-popper--theme-tooltip .v-popper__arrow-container {
  display: none;
}
</style>
