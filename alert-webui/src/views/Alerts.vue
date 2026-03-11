<template>
  <div class="alerts">
    <audio
      ref="audio"
      :src="audioURL"
    />



    <div
      class="severity-strip"
    >
      <v-menu
        offset-y
        left
      >
        <template v-slot:activator="{ on, attrs }">
          <div
            class="d-flex align-center custom-env-menu pointer"
            v-bind="attrs"
            v-on="on"
          >
            <span class="env-key-label">环境</span>
            <span class="env-val">{{ environ }}</span>
            <v-icon
              small
              class="env-icon"
            >
              arrow_drop_down
            </v-icon>
          </div>
        </template>
        <v-list
          dense
          class="py-0"
        >
          <v-list-tile
            v-for="env in environments"
            :key="env"
            @click="environ = env"
          >
            <v-list-tile-title style="font-size: 11px; font-weight: 500;">
              {{ env }}
            </v-list-tile-title>
          </v-list-tile>
        </v-list>
      </v-menu>
      <span class="strip-separator">|</span>
      <div
        v-for="severity in severityOrder"
        :key="severity"
        class="severity-item"
      >
        <v-icon
          class="severity-dot"
          :style="{ color: severityColor(severity) }"
        >
          fiber_manual_record
        </v-icon>
        <span class="severity-count">
          {{ counts[severity] || counts[severity.toLowerCase()] || counts[severity.charAt(0).toUpperCase() + severity.slice(1)] || 0 }}
        </span>
        <span class="severity-name grey--text text--darken-1">
          {{ severity.toLowerCase() === 'informational' ? 'Info' : severity }}
        </span>
      </div>

      <v-spacer />

      <div class="header-actions">
        <v-tooltip bottom>
          <template v-slot:activator="{ on, attrs }">
            <v-btn
              flat
              icon
              class="ma-0"
              :class="{ 'filter-active': isActive }"
              v-bind="attrs"
              v-on="on"
              @click="sidesheet = !sidesheet"
            >
              <v-icon>filter_list</v-icon>
            </v-btn>
          </template>
          <span>{{ $t('Filters') }}</span>
        </v-tooltip>

        <v-tooltip bottom>
          <template v-slot:activator="{ on, attrs }">
            <v-btn
              flat
              icon
              class="ma-0"
              v-bind="attrs"
              :loading="isRefreshing"
              v-on="on"
              @click="refreshAlerts"
            >
              <v-icon>refresh</v-icon>
            </v-btn>
          </template>
          <span>{{ $t('Refresh') }}</span>
        </v-tooltip>

        <v-menu
          v-model="refreshMenu"
          offset-y
          left
        >
          <template v-slot:activator="{ on }">
            <v-btn
              flat
              class="ma-0 px-2"
              style="min-width: auto; height: 36px; text-transform: none;"
              v-on="on"
            >
              <span class="caption grey--text text--darken-2">Auto: {{ selectedRefreshInterval === 0 ? 'Off' : (selectedRefreshInterval/1000) + 's' }}</span>
              <v-icon
                right
                small
                color="grey darken-2"
              >
                arrow_drop_down
              </v-icon>
            </v-btn>
          </template>
          <v-list dense>
            <v-list-tile
              v-for="option in refreshOptions"
              :key="option.value"
              @click="setRefreshInterval(option.value)"
            >
              <v-list-tile-title>{{ option.text }}</v-list-tile-title>
            </v-list-tile>
          </v-list>
        </v-menu>

        <v-tooltip bottom>
          <template v-slot:activator="{ on, attrs }">
            <v-btn
              flat
              icon
              class="ma-0"
              v-bind="attrs"
              v-on="on"
              @click="toCsv(alertsByEnvironment)"
            >
              <v-icon>cloud_download</v-icon>
            </v-btn>
          </template>
          <span>{{ $t('DownloadAsCsv') }}</span>
        </v-tooltip>
      </div>
    </div>

    <!-- Filter Bar (Chips) -->
    <v-fade-transition>
      <div
        v-if="activeFilters.length > 0"
        class="filter-bar grey lighten-4"
      >
        <v-chip
          v-for="f in activeFilters"
          :key="f.id"
          small
          close
          outline
          label
          color="primary"
          class="filter-chip"
          @input="removeFilter(f)"
        >
          <span class="font-weight-medium mr-1">{{ f.label }}:</span>
          <span>{{ f.text }}</span>
        </v-chip>
        <v-btn
          flat
          small
          color="grey darken-1"
          class="text-none ml-2"
          @click="clearAllFilters"
        >
          {{ $t('ClearAll') }}
        </v-btn>
      </div>
    </v-fade-transition>

    <alert-list
      :alerts="alertsByEnvironment"
      @set-alert="setAlert"
    />

    <alert-list-filter
      :value="sidesheet"
      @close="sidesheet = false"
    />
    <v-navigation-drawer
      v-model="detailDrawer"
      right
      fixed
      temporary
      width="800"
      hide-overlay
      class="elevation-4"
    >
      <alert-detail
        v-if="selectedAlertId"
        :id="selectedAlertId"
        @close="detailDrawer = false"
      />
    </v-navigation-drawer>
  </div>
</template>

<script>
import AlertList from '@/components/AlertList.vue'
import AlertDetail from '@/components/AlertDetail.vue'

import moment from 'moment'
import { ExportToCsv } from 'export-to-csv'
import utils from '@/common/utils'
import i18n from '@/plugins/i18n'

export default {
  components: {
    AlertList,
    AlertDetail,
    AlertListFilter: () => import('@/components/AlertListFilter.vue')
  },
  props: {
    query: {
      type: Object,
      required: false,
      default: () => {}
    },
    isKiosk: {
      type: String,
      required: false,
      default: null
    },
    hash: {
      type: String,
      required: false,
      default: ''
    }
  },
  data: () => ({
    detailDrawer: false,
    selectedAlertId: null,
    selectedId: null,
    selectedItem: {},
    timer: null,
    refreshMenu: false,
    selectedRefreshInterval: 5000,
    isRefreshing: false,
    refreshOptions: [
      { text: 'Off', value: 0 },
      { text: '5s', value: 5000 },
      { text: '10s', value: 10000 },
      { text: '30s', value: 30000 },
      { text: '1m', value: 60000 },
      { text: '5m', value: 300000 }
    ]
  }),
  computed: {
    audioURL() {
      return this.$config.audio.new || this.$store.getters.getPreference('audioURL')
    },

    filter() {
      return this.$store.state.alerts.filter
    },
    isActive() {
      return this.filter.text || this.filter.status || this.filter.customer || this.filter.service || this.filter.group || this.filter.dateRange[0] || this.filter.dateRange[1]
    },
    indicators() {
      return this.$config.indicators ? this.$config.indicators.queries  : []
    },
    alerts() {
      if (this.filter) {
        return this.$store.getters['alerts/alerts']
          .filter(alert =>
            this.filter.text
              ? Object.keys(alert).some(k => alert[k] && alert[k].toString().toLowerCase().includes(this.filter.text.toLowerCase()))
              : true
          )
      } else {
        return this.$store.getters['alerts/alerts']
      }
    },
    isNewOpenAlerts() {
      return this.alerts
        .filter(alert => this.filter.environment ? this.filter.environment == alert.environment : true)
        .filter(alert => alert.status == 'open')
        .reduce((acc, alert) => acc || !alert.repeat, false)
    },

    alertsByEnvironment() {
      return this.alerts.filter(alert =>
        this.filter.environment
          ? alert.environment === this.filter.environment
          : true
      )
    },
    severityOrder() {
      let severities = []
      if (this.$config.indicators && this.$config.indicators.severity) {
        severities = this.$config.indicators.severity
      } else {
        const severityMap = this.$store.getters.getConfig('severity') || this.$store.getters.getConfig('alarm_model').severity
        if (severityMap) {
          severities = Object.keys(severityMap).sort((a, b) => severityMap[a] - severityMap[b])
        } else {
          severities = ['security', 'critical', 'major', 'minor', 'warning', 'indeterminate', 'unknown']
        }
      }
      const ignoredSeverities = ['debug', 'trace', 'informational', 'info', 'normal', 'cleared', 'ok']
      const filtered = severities.filter(s => !ignoredSeverities.includes(s.toLowerCase()))
      
      // Ensure 'indeterminate' and 'unknown' are always present as requested by user
      if (!filtered.includes('indeterminate')) filtered.push('indeterminate')
      if (!filtered.includes('unknown')) filtered.push('unknown')
      
      return filtered
    },
    counts() {
      // If we have an environment selected, get its counts from the store
      if (this.filter.environment) {
        const env = this.$store.state.alerts.environments.find(e => e.environment === this.filter.environment)
        return env ? env.severityCounts : {}
      }
      // Otherwise aggregate all environments
      return this.$store.state.alerts.environments.reduce((acc, env) => {
        Object.keys(env.severityCounts || {}).forEach(sev => {
          acc[sev] = (acc[sev] || 0) + env.severityCounts[sev]
        })
        return acc
      }, {})
    },
    environ: {
      get() {
        return this.filter.environment || 'ALL'
      },
      set(value) {
        this.$store.dispatch('alerts/setFilter', {
          environment: value === 'ALL' ? null : value
        })
      }
    },

    activeFilters() {
      const chips = []
      if (this.filter.text) {
        chips.push({ id: 'text', label: this.$t('Search'), text: this.filter.text, type: 'text' })
      }
      if (this.filter.status && this.filter.status.length > 0) {
        this.filter.status.forEach(s => {
          chips.push({ id: `status-${s}`, label: this.$t('Status'), text: this.$t('status_' + s), value: s, type: 'status' })
        })
      }
      if (this.filter.severity && this.filter.severity.length > 0) {
        this.filter.severity.forEach(s => {
          chips.push({ id: `severity-${s}`, label: this.$t('Severity'), text: s.charAt(0).toUpperCase() + s.slice(1), value: s, type: 'severity' })
        })
      }
      return chips
    },
    environments() {
      return ['ALL', ...this.$store.getters['alerts/environments'](false)]
    },
    refreshInterval() {
      return (
        this.$store.getters.getPreference('refreshInterval') ||
        this.$store.getters.getConfig('refresh_interval')
      )
    },
    autoRefresh() {
      return true // FIXME: autoRefresh setting comes from server in alert response
    },
    refresh() {
      return this.$store.state.refresh
    },
    isLoggedIn() {
      return this.$store.getters['auth/isLoggedIn']
    },
    isMute() {
      return this.$store.getters.getPreference('isMute')
    },
    showPanel: {
      get() {
        return this.$store.state.alerts.showPanel
      },
      set(value) {
        this.$store.dispatch('alerts/toggle', ['showPanel', value])
      }
    },
    sidesheet: {
      get() {
        return this.$store.state.alerts.sidesheet
      },
      set(value) {
        this.$store.dispatch('alerts/toggle', ['sidesheet', value])
      }
    },

    pagination() {
      return this.$store.state.alerts.pagination
    }
  },
  watch: {

    filter: {
      handler(val) {
        history.pushState(null, null, this.$store.getters['alerts/getHash'])

        this.cancelTimer()
        this.refreshAlerts()
      },
      deep: true
    },
    pagination: {
      handler(newVal, oldVal) {
        history.pushState(null, null, this.$store.getters['alerts/getHash'])
        if (oldVal.page != newVal.page ||
          oldVal.rowsPerPage != newVal.rowsPerPage ||
          oldVal.sortBy != newVal.sortBy ||
          oldVal.descending != newVal.descending
        ) {
          this.getAlerts()
          this.getEnvironments()
        }
      }
    },
    refresh(val) {
      val || this.getAlerts() && this.getEnvironments()
    },
    showPanel(val) {
      history.pushState(null, null, this.$store.getters['alerts/getHash'])
    }
  },
  created() {
    this.setSearch(this.query)
    if (this.hash) {
      let hashMap = utils.fromHash(this.hash)
      this.setFilter(hashMap)
      this.setSort(hashMap)
      this.setPanel(hashMap)
    }

    this.setKiosk(this.isKiosk)
    this.selectedRefreshInterval = this.refreshInterval
    this.cancelTimer()
    this.refreshAlerts()
  },
  beforeDestroy() {
    this.cancelTimer()
  },
  methods: {
    setSearch(query) {
      this.$store.dispatch('alerts/updateQuery', query)
    },
    setFilter(filter) {
      this.$store.dispatch('alerts/setFilter', {
        environment: filter.environment,
        text: filter.text,
        status: filter.status ? filter.status.split(',') : null,
        customer: filter.customer ? filter.customer.split(',') : null,
        service: filter.service ? filter.service.split(',') : null,
        group: filter.group ? filter.group.split(',') : null,
        dateRange: filter.dateRange ? filter.dateRange.split(',').map(n => n ? parseInt(n) : null) : [null, null]
      })
    },
    setSort(sort) {
      this.$store.dispatch('alerts/setPagination', {
        descending: sort.sd == '1',
        sortBy: sort.sb
      })
    },
    setPage(page) {
      this.$store.dispatch('alerts/setPagination', {page: page})
    },
    setPanel(panel) {
      this.$store.dispatch('alerts/setPanel', panel.asi == '1')
    },
    setKiosk(isKiosk) {
      this.$store.dispatch('alerts/updateKiosk', isKiosk)
    },
    getAlerts() {
      return this.$store.dispatch('alerts/getAlerts')
    },
    getEnvironments() {
      this.$store.dispatch('alerts/getEnvironments')
    },
    playSound() {
      !this.isMute && this.$refs.audio.play()
    },

    setAlert(item) {
      this.selectedAlertId = item.id
      this.detailDrawer = true
    },
    refreshAlerts() {
      this.cancelTimer()
      this.isRefreshing = true
      this.getEnvironments()
      this.getAlerts()
        .then(() => {
          this.isRefreshing = false
          this.isNewOpenAlerts && this.playSound()
          if (this.autoRefresh && this.selectedRefreshInterval > 0) {
            this.timer = setTimeout(() => this.refreshAlerts(), this.selectedRefreshInterval)
          }
        })
        .catch(() => {
          this.isRefreshing = false
        })
    },
    setRefreshInterval(val) {
      this.selectedRefreshInterval = val
      this.refreshAlerts()
    },
    removeFilter(f) {
      this.isRefreshing = true
      let promise
      if (f.type === 'text') {
        promise = this.$store.dispatch('alerts/setFilter', { text: null })
      } else if (f.type === 'status') {
        const newStatus = this.filter.status.filter(s => s !== f.value)
        promise = this.$store.dispatch('alerts/setFilter', { status: newStatus.length > 0 ? newStatus : null })
      } else if (f.type === 'severity') {
        const newSeverity = this.filter.severity.filter(s => s !== f.value)
        promise = this.$store.dispatch('alerts/setFilter', { severity: newSeverity.length > 0 ? newSeverity : null })
      }
      if (promise) {
        promise.finally(() => {
          this.isRefreshing = false
        })
      } else {
        this.isRefreshing = false
      }
    },
    clearAllFilters() {
      this.isRefreshing = true
      this.$store.dispatch('alerts/setFilter', {
        text: null,
        status: null,
        severity: null
      }).then(() => {
        this.isRefreshing = false
      }).catch(() => {
        this.isRefreshing = false
      })
    },
    cancelTimer() {
      if (this.timer) {
        clearTimeout(this.timer)
        this.timer = null
      }
    },
    filterBySeverity(severity) {
      if (this.filter.severity === severity) {
        this.$store.dispatch('alerts/setFilter', { severity: null })
      } else {
        this.$store.dispatch('alerts/setFilter', { severity: severity })
      }
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
    severityColor(severity) {
      const colors = this.$store.getters.getConfig('colors')
      if (colors && colors.severity && colors.severity[severity]) {
        return colors.severity[severity]
      }
      // Fallback to alarm_model if root colors is missing
      const alarmModel = this.$store.getters.getConfig('alarm_model')
      if (alarmModel && alarmModel.colors && alarmModel.colors.severity && alarmModel.colors.severity[severity]) {
        return alarmModel.colors.severity[severity]
      }
      return 'grey'
    }
  }
}
</script>

<style>
.filter-active::after {
  background-color: rgb(255, 82, 82);
  border-radius: 50%;
  box-sizing: border-box;
  content: " ";
  height: 8px;
  position: absolute;
  right: 7px;
  top: 9px;
  width: 8px;
}
.pointer {
  cursor: pointer;
}
.header-actions {
  display: flex !important;
  align-items: center;
  flex-wrap: nowrap;
  gap: 4px;
}
.severity-strip {
  display: flex;
  flex-wrap: nowrap;
  align-items: center;
  height: 48px;
  padding: 0 12px 0 24px;
  border-bottom: 1px solid rgba(0,0,0,0.08);
  font-size: 13px;
  font-weight: 500;
  gap: 0;
  position: relative;
  z-index: 4;
  background-color: inherit;
}

/* "环境" label */
.env-key-label {
  font-size: 14px;
  font-weight: 500;
  color: rgba(0,0,0,0.6);
  white-space: nowrap;
  flex-shrink: 0;
  margin-right: 6px;
}

/* "|" separator */
.strip-separator {
  color: rgba(0,0,0,0.15);
  margin: 0 8px;
  font-size: 14px;
  line-height: 48px;
}

/* Custom Env Menu */
.custom-env-menu {
  height: 48px;
  padding: 0 4px 0 0;
}
.env-val {
  font-size: 13px;
  font-weight: 500;
  color: rgba(0,0,0,0.87);
  line-height: 48px;
  margin: 0 2px 0 6px;
}
.env-icon {
  font-size: 16px !important;
  color: rgba(0,0,0,0.54) !important;
}
.filter-bar {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  padding: 4px 12px;
  border-bottom: 1px solid rgba(0,0,0,0.08);
  min-height: 40px;
  gap: 4px;
}
.filter-chip {
  height: 24px;
  margin: 2px !important;
  font-size: 12px;
}
.filter-chip .v-chip__content {
  cursor: default;
}

/* Severity items */
.severity-item {
  display: inline-flex;
  align-items: center;
  white-space: nowrap;
  margin-right: 12px;
  line-height: 48px;
}
.severity-dot {
  font-size: 12px !important;
}
.severity-count {
  margin-left: 2px;
}
.severity-name {
  font-size: 13px;
  text-transform: capitalize;
  margin-left: 2px;
}
.severity-active {
  background: rgba(0,0,0,0.06);
  border-radius: 4px;
  padding: 2px 4px;
}
</style>

