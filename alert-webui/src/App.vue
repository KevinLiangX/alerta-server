<template>
  <v-app
    id="alerta"
    :dark="isDark"
  >
    <div v-if="!isKiosk">
      <v-navigation-drawer
        v-if="isLoggedIn || !isAuthRequired || isAllowReadonly"
        v-model="drawer"
        :mini-variant="mini"
        :clipped="true"
        disable-resize-watcher
        fixed
        app
        width="220"
        class="custom-drawer"
      >
        <v-list
          dense
          class="pt-2"
        >
          <template v-for="(item, index) in items">
            <template v-if="item.icon && item.show">
              <v-tooltip
                :key="item.text"
                right
                :disabled="!mini"
              >
                <template v-slot:activator="{ on }">
                  <v-list-tile
                    v-has-perms="item.perms"
                    :to="item.path"
                    active-class="sidebar-active-item"
                    v-on="on"
                  >
                    <v-list-tile-action>
                      <v-icon>{{ item.icon }}</v-icon>
                    </v-list-tile-action>
                    <v-list-tile-content>
                      <v-list-tile-title>
                        {{ item.text }}
                        <v-icon
                          v-if="item.appendIcon"
                          small
                        >
                          {{ item.appendIcon }}
                        </v-icon>
                      </v-list-tile-title>
                    </v-list-tile-content>
                  </v-list-tile>
                </template>
                <span>{{ item.text }}</span>
              </v-tooltip>
            </template>

            <v-list-group
              v-else-if="item.queries && item.queries.length > 0"
              :key="item.text"
              :prepend-icon="item.model ? item.icon : item['icon-alt']"
              sub-group
              no-action
            >
              <template v-slot:activator>
                <v-tooltip
                  right
                  :disabled="!mini"
                >
                  <template v-slot:activator="{ on }">
                    <v-list-tile v-on="on">
                      <v-list-tile-title>
                        {{ item.text }}
                      </v-list-tile-title>
                    </v-list-tile>
                  </template>
                  <span>{{ item.text }}</span>
                </v-tooltip>
              </template>
              <v-list-tile
                v-for="(q, i) in item.queries"
                :key="i"
                @click="submitSearch(q.query)"
              >
                <v-list-tile-title v-text="q.text" />
                <v-list-tile-action>
                  <v-icon
                    small
                    @click.stop="deleteSearch(q)"
                    v-text="q.icon"
                  />
                </v-list-tile-action>
              </v-list-tile>
            </v-list-group>

            <v-divider
              v-else-if="item.divider"
              :key="index + '-divider'"
            />
          </template>
        </v-list>

        <v-list
          class="bottom-toggle"
          dense
        >
          <v-divider />
          <v-list-tile @click.stop="$vuetify.breakpoint.lgAndUp ? (mini = !mini) : (drawer = !drawer)">
            <v-list-tile-action>
              <v-icon>{{ mini ? 'chevron_right' : 'chevron_left' }}</v-icon>
            </v-list-tile-action>
            <v-list-tile-content v-show="!mini">
              <v-list-tile-title>收起侧边栏</v-list-tile-title>
            </v-list-tile-content>
          </v-list-tile>
        </v-list>
      </v-navigation-drawer>
    </div>


    <v-content>
      <banner />
      <router-view />
      <snackbar />
    </v-content>

    <div v-if="!isKiosk">
      <span class="hidden-sm-and-up" />
    </div>
  </v-app>
</template>

<script>
import Banner from '@/components/lib/Banner.vue'
import Snackbar from '@/components/lib/Snackbar.vue'

import moment from 'moment'
import { ExportToCsv } from 'export-to-csv'
import i18n from '@/plugins/i18n'

export default {
  name: 'App',
  components: {
    Banner,
    Snackbar
  },
  props: [],
  data: () => ({
    hasFocus: false,
    menu: false,
    message: false,
    hints: true,
    dialog: false,
    drawer: true,
    mini: false,
    navbar: {
      signin: { icon: 'account_circle', text: i18n.t('SignIn'), path: '/login' }
    },
    error: false
  }),
  computed: {
    items() {
      return [
        {
          icon: 'list',
          text: '告警管理',
          path: '/alerts',
          perms: 'read:alerts',
          show: true
        },
        {
          icon: 'expand_less',
          'icon-alt': 'expand_more',
          text: '搜索条件',
          model: false,
          queries: this.queries
        },

        {
          icon: 'assessment',
          text: '统计报表',
          path: '/reports',
          perms: 'read:alerts',
          show: true
        },
        { divider: true}
      ]
    },
    isDark() {
      return this.$store.getters.getPreference('isDark')
    },
    isWatch() {
      return this.$store.state.alerts.isWatch
    },
    isActive() {
      const filter = this.$store.state.alerts.filter
      return filter.text || filter.status || filter.customer || filter.service || filter.group || filter.dateRange[0] || filter.dateRange[1]
    },
    languagePref() {
      return this.$store.getters.getPreference('languagePref')
    },
    isKiosk() {
      return this.$store.state.alerts.isKiosk
    },
    isLoggedIn() {
      return this.$store.getters['auth/isLoggedIn']
    },
    isAuthRequired() {
      return this.$config.auth_required
    },
    isAllowReadonly() {
      return this.$config.allow_readonly
    },
    isSignupEnabled() {
      return this.$config.signup_enabled
    },
    profile() {
      return this.$store.state.auth.payload || {}
    },
    query: {
      get() {
        return this.$store.state.alerts.query
          ? this.$store.state.alerts.query.q
          : null
      },
      set(value) {
        // FIXME: offer query suggestions to user here, in future
      }
    },
    queries() {
      return this.$store.getters.getUserQueries.map(query => (
        {
          icon: 'remove_circle_outline',
          text: query.text,
          path: '/alerts',
          query: query.q,
          perms: 'read:alerts',
          show: true
        }))
    },
    actions() {
      return this.$config.actions
    },
    sidesheet: {
      get() {
        return this.$store.state.alerts.sidesheet
      },
      set(value) {
        this.$store.dispatch('alerts/toggle', ['sidesheet', value])
      }
    },
    alertsByEnvironment() {
      const alerts = this.$store.getters['alerts/alerts']
      const filter = this.$store.state.alerts.filter
      return alerts.filter(alert =>
        filter.environment
          ? alert.environment === filter.environment
          : true
      )
    },
    selected() {
      return this.$store.state.alerts.selected
    },
    ackTimeout() {
      return this.$store.getters.getPreference('ackTimeout')
    },
    shelveTimeout() {
      return this.$store.getters.getPreference('shelveTimeout')
    },
    username() {
      return this.$store.getters['auth/getUsername']
    },
    avatar() {
      return this.$store.getters['auth/getAvatar']
    }
  },
  watch: {
    isKiosk(val) {
      if (val) {
        this.toggleFullScreen()
      }
    },
    languagePref(val) {
      i18n.locale = val
    }
  },
  mounted() {
    if (this.isLoggedIn) {
      this.$store.dispatch('getUserPrefs')
      this.$store.dispatch('getUserQueries')
    }
  },
  methods: {
    submitSearch(query) {
      this.$store.dispatch('alerts/updateQuery', { q: query })
      this.$router.push({
        query: { ...this.$router.query, q: query },
        hash: this.$store.getters['alerts/getHash']
      })
      this.refresh()
    },
    clearSearch() {
      this.query = null
      this.$store.dispatch('alerts/updateQuery', {})
      this.$router.push({
        query: { ...this.$router.query, q: undefined },
        hash: this.$store.getters['alerts/getHash']
      })
      this.refresh()
    },
    clearSelected() {
      this.$store.dispatch('alerts/updateSelected', [])
    },
    saveSearch() {
      if (this.query) {
        this.$store.dispatch('addUserQuery', {
          text: this.query,
          q: this.query
        })
      }
    },
    deleteSearch(query) {
      this.$store.dispatch('removeUserQuery', query)
    },
    takeBulkAction(action) {
      Promise.all(this.selected.map(a => this.$store.dispatch('alerts/takeAction', [a.id, action, '']))).then(() => {
        this.clearSelected()
        this.$store.dispatch('alerts/getAlerts')
      })
    },
    bulkAckAlert() {
      this.selected.map(a => {
        this.$store
          .dispatch('alerts/takeAction', [
            a.id,
            'ack',
            '',
            this.ackTimeout
          ])
      })
        .reduce(() => this.clearSelected())
    },
    bulkShelveAlert() {
      Promise.all(this.selected.map(a => {
        this.$store
          .dispatch('alerts/takeAction', [
            a.id,
            'shelve',
            '',
            this.shelveTimeout
          ])
      })).then(() => {
        this.clearSelected()
        this.$store.dispatch('alerts/getAlerts')
      })
    },
    isWatched(tags) {
      const tag = `watch:${this.username}`
      return tags ? tags.indexOf(tag) > -1 : false
    },
    toggleWatch() {
      var map
      if (this.selected.some(x => !this.isWatched(x.tags))) {
        map = this.selected.map(a => this.watchAlert(a.id))
      } else {
        map = this.selected.map(a => this.unwatchAlert(a.id))
      }
    
      Promise.all(map).then(() => {
        this.clearSelected()
        this.$store.dispatch('alerts/getAlerts')
      })
    },
    refreshAlerts() {
      this.$store.dispatch('alerts/getAlerts')
    },
    toggleSidesheet() {
      this.sidesheet = !this.sidesheet
    },
    toCsv(data) {
      const filter = this.$store.state.alerts.filter
      const options = {
        fieldSeparator: ',',
        filename: `Alerts_${filter.environment || 'ALL'}`,
        quoteStrings: '"',
        decimalSeparator: '.',
        showLabels: true,
        showTitle: false,
        useTextFile: false,
        useBom: true,
        useKeysAsHeaders: true
      }
      let attrs = {}
      data.map(d => Object.keys(d.attributes).forEach((attr) => attrs['attributes.'+attr] = d.attributes[attr]))

      const csvExporter = new ExportToCsv(options)
      csvExporter.generateCsv(data.map(({ correlate, service, tags, attributes, rawData, history, ...item }) => ({
        correlate: correlate.join(','),
        service: service.join(','),
        tags: tags.join(','),
        ...attrs,
        ...item,
        rawData: rawData ? rawData.toString() : ''
      })))
    },
    watchAlert(id) {
      this.$store.dispatch('alerts/watchAlert', id)
    },
    unwatchAlert(id) {
      this.$store.dispatch('alerts/unwatchAlert', id)
    },
    bulkDeleteAlert() {
      confirm(i18n.t('ConfirmDelete')) &&
        Promise.all(this.selected.map(a => this.$store.dispatch('alerts/deleteAlert', a.id, false))).then(() => {
          this.clearSelected()
          this.$store.dispatch('alerts/getAlerts')
        })
    },
    toggle(sw, value) {
      this.$store.dispatch('alerts/toggle', [sw, value])
    },
    toggleFullScreen() {
      let elem = document.getElementById('alerta')
      if (!this.isFullscreen()) {
        elem.requestFullscreen()
      } else {
        document.exitFullscreen()
      }
    },
    isFullscreen() {
      return document.fullscreenElement
    },
    refresh() {
      this.$store.dispatch('set', ['refresh', true])
      setTimeout(() => {
        this.$store.dispatch('set', ['refresh', false])
      }, 300)
    }
  }
}
</script>

<style>

@import "./assets/css/fonts.css";

.toolbar-title {
  color: inherit;
  text-decoration: inherit;
}

.logo {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  font-size: 20px;
  font-weight: 600;
  letter-spacing: 1px;
}

/* Sidebar Flexbox Layout & Toggle */
.custom-drawer .v-navigation-drawer__border {
  display: block;
}
.custom-drawer > .v-list:first-child {
  height: calc(100% - 49px);
  overflow-y: auto;
}
.custom-drawer .bottom-toggle {
  position: absolute;
  bottom: 0;
  width: 100%;
  padding: 0;
  background-color: inherit;
}

/* Modern Sidebar Active State */
.sidebar-active-item {
  position: relative;
  background-color: var(--v-primary-base, rgba(25, 118, 210, 0.08)) !important;
  color: var(--v-primary-base, #1976D2) !important;
  font-weight: 500;
}
.sidebar-active-item::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 4px;
  background-color: var(--v-primary-base, #1976D2);
  border-radius: 0 4px 4px 0;
}
.sidebar-active-item .v-icon {
  color: inherit !important;
}

.btn--plain {
  padding: 0;
  opacity: 0.6;
}
.btn--plain:before {
  background-color: transparent !important;
  transition: none !important;
}
.btn--plain:hover {
  opacity: 1;
}
</style>
