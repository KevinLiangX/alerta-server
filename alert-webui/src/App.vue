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

      <!-- Bulk Actions FAB -->
      <v-slide-y-reverse-transition>
        <div v-if="selected.length > 0 && !isKiosk" class="bulk-fab-container">
          <div class="bulk-fab-bar primary elevation-6">
            <span class="subheading font-weight-medium mr-3 white--text">已选择 {{ selected.length }} 项</span>
            <v-divider vertical dark class="mx-2"></v-divider>
            
            <v-btn flat dark small @click="takeBulkAction('open')" class="white--text" v-if="isBulkClosed">
              <v-icon left>refresh</v-icon> {{ $t('status_open') }}
            </v-btn>
            <v-btn flat dark small @click="bulkAckAlert" class="white--text" v-if="isBulkOpen">
              <v-icon left>check</v-icon> {{ $t('status_ack') }}
            </v-btn>
            <v-btn flat dark small @click="takeBulkAction('unack')" class="white--text" v-if="isBulkAcked">
              <v-icon left>undo</v-icon> {{ $t('Unack') }}
            </v-btn>
            <v-btn flat dark small @click="takeBulkAction('unshelve')" class="white--text" v-if="isBulkShelved">
              <v-icon left>restore</v-icon> {{ $t('Unshelve') }}
            </v-btn>
            <v-btn flat dark small @click="bulkShelveAlert" class="white--text" v-if="isBulkOpen || isBulkAcked">
              <v-icon left>schedule</v-icon> {{ $t('status_shelved') }}
            </v-btn>
            <v-btn flat dark small @click="takeBulkAction('close')" class="white--text" v-if="isBulkOpen || isBulkAcked || isBulkShelved">
              <v-icon left>highlight_off</v-icon> {{ $t('status_closed') }}
            </v-btn>
            
            <v-btn flat dark small @click="dialogNote = true" class="white--text">
              <v-icon left>note_add</v-icon> {{ $t('AddNote') }}
            </v-btn>
            
            <v-menu offset-y top>
              <template v-slot:activator="{ on }">
                <v-btn flat dark small v-on="on" class="white--text">
                  更多 <v-icon right>arrow_drop_up</v-icon>
                </v-btn>
              </template>
              <v-list dense>
                <v-list-tile @click="bulkDeleteAlert">
                  <v-list-tile-title class="red--text text--darken-2">
                    <v-icon left color="red darken-2" small>delete</v-icon> {{ $t('Delete') }}
                  </v-list-tile-title>
                </v-list-tile>
              </v-list>
            </v-menu>

            <v-divider vertical dark class="mx-2"></v-divider>
            <v-btn icon dark small @click="clearSelected" class="ma-0">
              <v-icon>close</v-icon>
            </v-btn>
          </div>
        </div>
      </v-slide-y-reverse-transition>

      <!-- Batch Add Note Dialog -->
      <v-dialog v-model="dialogNote" max-width="500px">
        <v-card>
          <v-card-title>
            <span class="headline">批量添加备注</span>
          </v-card-title>
          <v-card-text>
            <v-text-field
              v-model.trim="noteText"
              :label="$t('AddNote')"
              prepend-icon="edit"
              required
              @keyup.enter="bulkAddNote"
            ></v-text-field>
          </v-card-text>
          <v-card-actions>
            <v-spacer></v-spacer>
            <v-btn color="blue darken-1" flat @click="dialogNote = false">{{ $t('Cancel') }}</v-btn>
            <v-btn color="blue darken-1" flat @click="bulkAddNote" :disabled="!noteText">{{ $t('Submit') }}</v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>

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
    dialogNote: false,
    noteText: '',
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
    bulkStatus() {
      return this.selected.length > 0 ? this.selected[0].status : null
    },
    isBulkOpen() {
      return this.bulkStatus == 'open' || this.bulkStatus == 'NORM' || this.bulkStatus == 'UNACK' || this.bulkStatus == 'RTNUN'
    },
    isBulkAcked() {
      return this.bulkStatus == 'ack' || this.bulkStatus == 'ACKED'
    },
    isBulkShelved() {
      return this.bulkStatus == 'shelved' || this.bulkStatus == 'SHLVD'
    },
    isBulkClosed() {
      return this.bulkStatus == 'closed' || this.bulkStatus == 'OK'
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
      let filtered = this.selected
      if (action === 'close') {
        filtered = this.selected.filter(a => a.status !== 'closed' && a.status !== 'OK')
      }
      Promise.all(filtered.map(a => this.$store.dispatch('alerts/takeAction', [a.id, action, '']))).then(() => {
        this.clearSelected()
        this.$store.dispatch('alerts/getAlerts')
      })
    },
    bulkAckAlert() {
      const filtered = this.selected.filter(a => a.status !== 'ack' && a.status !== 'ACKED' && a.status !== 'closed')
      Promise.all(filtered.map(a => 
        this.$store.dispatch('alerts/takeAction', [
          a.id,
          'ack',
          '',
          this.ackTimeout
        ])
      )).then(() => {
        this.clearSelected()
        this.$store.dispatch('alerts/getAlerts')
      })
    },
    bulkAddNote() {
      if (!this.noteText) return
      Promise.all(this.selected.map(a => 
        this.$store.dispatch('alerts/addNote', [a.id, this.noteText])
      )).then(() => {
        this.dialogNote = false
        this.noteText = ''
        this.clearSelected()
        this.$store.dispatch('alerts/getAlerts')
      })
    },
    bulkShelveAlert() {
      const filtered = this.selected.filter(a => a.status !== 'shelved' && a.status !== 'SHLVD' && a.status !== 'closed')
      Promise.all(filtered.map(a => 
        this.$store.dispatch('alerts/takeAction', [
          a.id,
          'shelve',
          '',
          this.shelveTimeout
        ])
      )).then(() => {
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

.bulk-fab-container {
  position: fixed;
  bottom: 24px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 100 !important;
}

.bulk-fab-bar {
  border-radius: 8px !important;
  padding: 8px 16px;
  display: flex;
  align-items: center;
}

.bulk-fab-bar .v-btn {
  text-transform: none;
  font-weight: 500;
  margin: 0 2px;
}

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
