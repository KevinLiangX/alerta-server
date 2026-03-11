<template>
  <div>
    <v-data-table
      v-model="selected"
      :headers="customHeaders"
      :items="alerts"
      item-key="id"
      :pagination.sync="pagination"
      :total-items="pagination.totalItems"
      :rows-per-page-items="pagination.rowsPerPageItems"
      :loading="isSearching"
      class="alert-table comfortable"
      :style="columnWidths"
      sort-icon="arrow_drop_down"
      select-all
    >
      <template
        slot="items"
        slot-scope="props"
      >
        <tr
          :style="{ 'border-left': `4px solid ${severityColor(props.item.severity)}` }"
          class="hover-lighten"
          @click="selectItem(props.item)"
        >
          <td
            class="text-no-wrap"
            :style="fontStyle"
          >
            <div style="display: flex; align-items: center;">
              <v-checkbox
                v-model="props.selected"
                primary
                hide-details
                color="gray"
                class="select-box"
                :ripple="false"
                :size="fontSize"
                :disabled="selected.length > 0 && selected[0].status !== props.item.status"
                @click.stop
              />
              <v-tooltip v-if="lastNote(props.item)" bottom max-width="300">
                <template v-slot:activator="{ on, attrs }">
                  <v-icon
                    v-bind="attrs"
                    color="amber darken-2"
                    small
                    v-on="on"
                    class="ml-2"
                  >speaker_notes</v-icon>
                </template>
                <div class="pa-1">
                  <div class="mb-1" style="word-break: break-all;">{{ lastNote(props.item).text }}</div>
                  <div class="caption grey--text text--lighten-2">
                    <span v-if="lastNote(props.item).user && lastNote(props.item).user.toLowerCase() !== 'anonymous'">{{ lastNote(props.item).user }} · </span>
                    <date-time :value="lastNote(props.item).updateTime" format="shortTime" />
                  </div>
                </div>
              </v-tooltip>
            </div>
          </td>
          <td
            v-for="col in $config.columns"
            :key="col"
            class="text-no-wrap"
            :style="fontStyle"
          >
            <span
              v-if="col == 'id'"
            >
              {{ props.item.id | shortId }}
            </span>
            <span
              v-if="col == 'resource'"
            >
              {{ props.item.resource }}
            </span>
            <span
              v-if="col == 'event'"
            >
              {{ props.item.event }}
            </span>
            <span
              v-if="col == 'environment'"
            >
              {{ props.item.environment }}
            </span>
            <span
              v-if="col == 'severity'"
            >
              <span
                class="label"
                :style="[fontStyle, { backgroundColor: severityColor(props.item.severity) }]"
              >
                {{ props.item.severity | capitalize }}
              </span>
            </span>
            <span
              v-if="col == 'correlate'"
            >
              {{ props.item.correlate.join(', ') }}
            </span>
            <span
              v-if="col == 'status'"
            >
              <span
                class="label"
                :style="fontStyle"
              >
                {{ $t('status_' + props.item.status) }}
              </span>
            </span>
            <span
              v-if="col == 'service'"
            >
              {{ props.item.service.join(', ') }}
            </span>
            <span
              v-if="col == 'group'"
            >
              {{ props.item.group }}
            </span>
            <span
              v-if="col == 'value'"
            >
              <div class="fixed-table">
                <div class="text-truncate">
                  <span v-html="props.item.value" />
                </div>
              </div>
            </span>
            <span
              v-if="col == 'text'"
            >
              <v-tooltip
                bottom
                max-width="600px"
              >
                <template v-slot:activator="{ on }">
                  <div
                    class="fixed-table"
                    style="cursor: pointer; max-width: 300px;"
                    v-on="on"
                  >
                    <div
                      class="text-truncate"
                      style="text-overflow: ellipsis; overflow: hidden; white-space: nowrap;"
                    >
                      <span v-html="props.item.text" />
                    </div>
                  </div>
                </template>
                <span v-html="props.item.text" />
              </v-tooltip>
            </span>
            <span
              v-if="col == 'tags'"
            >
              <span
                v-for="tag in props.item.tags"
                :key="tag"
              ><span
                class="label"
                :style="fontStyle"
              >{{ tag }}</span>&nbsp;</span>
            </span>
            <span
              v-if="props.item.attributes.hasOwnProperty(col)"
            >
              <span v-html="props.item.attributes[col]" />
            </span>
            <span
              v-if="col == 'origin'"
            >
              {{ props.item.origin }}
            </span>
            <span
              v-if="col == 'type'"
            >
              <span
                class="label"
                :style="fontStyle"
              >
                {{ props.item.type | splitCaps }}
              </span>
            </span>
            <span
              v-if="col == 'createTime'"
            >
              <date-time
                :value="props.item.createTime"
                format="mediumDate"
              />
            </span>
            <span
              v-if="col == 'timeout'"
            >
              {{ props.item.timeout | hhmmss }}
            </span>
            <span
              v-if="col == 'timeoutLeft'"
              class="text-xs-right"
            >
              {{ timeoutLeft(props.item) | hhmmss }}
            </span>
            <!-- rawData not supported -->
            <span
              v-if="col == 'customer' && $config.customer_views"
            >
              {{ props.item.customer }}
            </span>
            <span
              v-if="col == 'duplicateCount'"
            >
              {{ props.item.duplicateCount }}
            </span>
            <span
              v-if="col == 'repeat'"
            >
              <span
                class="label"
                :style="fontStyle"
              >
                {{ props.item.repeat | capitalize }}
              </span>
            </span>
            <span
              v-if="col == 'previousSeverity'"
            >
              <span
                class="label"
                :style="[fontStyle, { backgroundColor: severityColor(props.item.previousSeverity) }]"
              >
                {{ props.item.previousSeverity | capitalize }}
              </span>
            </span>
            <!-- trendIndication not supported -->
            <span
              v-if="col == 'receiveTime'"
            >
              <date-time
                :value="props.item.receiveTime"
                format="mediumDate"
              />
            </span>
            <span
              v-if="col == 'duration'"
              class="text-xs-right"
            >
              {{ duration(props.item) | hhmmss }}
            </span>
            <span
              v-if="col == 'lastReceiveId'"
            >
              {{ props.item.lastReceiveId | shortId }}
            </span>
            <span
              v-if="col == 'lastReceiveTime'"
            >
              <date-time
                :value="props.item.lastReceiveTime"
                format="mediumDate"
              />
            </span>
            <!-- only history supported is most recent note -->
            <span
              v-if="col == 'note'"
            >
              {{ lastNote(props.item) }}
            </span>
          </td>
          <td class="text-no-wrap">
            <div class="action-buttons">
              ...&nbsp;
              <v-tooltip bottom>
                <template v-slot:activator="{ on, attrs }">
                  <v-btn
                    v-if="isAcked(props.item.status) || isClosed(props.item.status)"
                    v-bind="attrs"
                    flat
                    icon
                    small
                    class="btn--plain pa-0 ma-0"
                    v-on="on"
                    @click.stop="takeAction(props.item.id, 'open')"
                  >
                    <v-icon :size="fontSize">
                      refresh
                    </v-icon>
                  </v-btn>
                </template>
                <span>{{ $t('Open') }}</span>
              </v-tooltip>

              <v-tooltip bottom>
                <template v-slot:activator="{ on, attrs }">
                  <v-btn
                    v-if="isOpen(props.item.status)"
                    v-bind="attrs"
                    flat
                    icon
                    small
                    class="btn--plain pa-0 ma-0"
                    v-on="on"
                    @click.stop="ackAlert(props.item.id)"
                  >
                    <v-icon :size="fontSize">
                      check
                    </v-icon>
                  </v-btn>
                </template>
                <span>{{ $t('Ack') }}</span>
              </v-tooltip>

              <v-tooltip bottom>
                <template v-slot:activator="{ on, attrs }">
                  <v-btn
                    v-if="isAcked(props.item.status)"
                    v-bind="attrs"
                    flat
                    icon
                    small
                    class="btn--plain pa-0 ma-0"
                    v-on="on"
                    @click.stop="takeAction(props.item.id, 'unack')"
                  >
                    <v-icon :size="fontSize">
                      undo
                    </v-icon>
                  </v-btn>
                </template>
                <span>{{ $t('Unack') }}</span>
              </v-tooltip>

              <v-tooltip bottom>
                <template v-slot:activator="{ on, attrs }">
                  <v-btn
                    v-if="isOpen(props.item.status) || isAcked(props.item.status)"
                    v-bind="attrs"
                    flat
                    icon
                    small
                    class="btn--plain pa-0 ma-0"
                    v-on="on"
                    @click.stop="shelveAlert(props.item.id)"
                  >
                    <v-icon :size="fontSize">
                      schedule
                    </v-icon>
                  </v-btn>
                </template>
                <span>{{ $t('Shelve') }}</span>
              </v-tooltip>

              <v-tooltip bottom>
                <template v-slot:activator="{ on, attrs }">
                  <v-btn
                    v-if="isShelved(props.item.status)"
                    v-bind="attrs"
                    flat
                    icon
                    small
                    class="btn--plain pa-0 ma-0"
                    v-on="on"
                    @click.stop="takeAction(props.item.id, 'unshelve')"
                  >
                    <v-icon :size="fontSize">
                      restore
                    </v-icon>
                  </v-btn>
                </template>
                <span>{{ $t('Unshelve') }}</span>
              </v-tooltip>

              <v-tooltip bottom>
                <template v-slot:activator="{ on, attrs }">
                  <v-btn
                    v-if="!isClosed(props.item.status)"
                    v-bind="attrs"
                    flat
                    icon
                    small
                    class="btn--plain pa-0 ma-0"
                    v-on="on"
                    @click.stop="takeAction(props.item.id, 'close')"
                  >
                    <v-icon :size="fontSize">
                      highlight_off
                    </v-icon>
                  </v-btn>
                </template>
                <span>{{ $t('Close') }}</span>
              </v-tooltip>

              <v-tooltip bottom>
                <template v-slot:activator="{ on, attrs }">
                  <v-btn
                    v-bind="attrs"
                    flat
                    icon
                    small
                    class="btn--plain pa-0 ma-0"
                    v-on="on"
                    @click.stop="deleteAlert(props.item.id)"
                  >
                    <v-icon :size="fontSize">
                      delete
                    </v-icon>
                  </v-btn>
                </template>
                <span>{{ $t('Delete') }}</span>
              </v-tooltip>
              <!-- <v-btn
                flat
                icon
                small
                class="btn--plain pa-0 ma-0"
                @click.stop="clipboardCopy(JSON.stringify(props.item, null, 4))"
              >
                <v-icon
                  :size="fontSize"
                >
                  content_copy
                </v-icon>
              </v-btn> -->

              <!-- <v-menu
                bottom
                left
              >
                <v-btn
                  slot="activator"
                  flat
                  icon
                  small
                  class="btn--plain pa-0 ma-0"
                >
                  <v-icon small>
                    more_vert
                  </v-icon>
                </v-btn>

                <v-list
                  subheader
                >
                  <v-subheader>Actions</v-subheader>
                  <v-divider />
                  <v-list-tile
                    v-for="(action, i) in actions"
                    :key="i"
                    @click.stop="takeAction(props.item.id, action)"
                  >
                    <v-list-tile-title>{{ action | splitCaps }}</v-list-tile-title>
                  </v-list-tile>
                </v-list>
              </v-menu> -->
            </div>
          </td>
        </tr>
      </template>
      <template slot="no-data">
        <div class="text-xs-center">
          <span v-if="isLoading">{{ $t('Loading') }}...</span>
          <span v-if="!isLoading">{{ $t('NoDataAvailable') }}</span>
        </div>
      </template>
    </v-data-table>
  </div>
</template>

<script>
import debounce from 'lodash/debounce'
import get from 'lodash/get'
import DateTime from './lib/DateTime'
import moment from 'moment'
import i18n from '@/plugins/i18n'

export default {
  components: {
    DateTime
  },
  props: {
    alerts: {
      type: Array,
      default: () => []
    }
  },
  data: vm => ({
    search: '',
    headersMap: {
      id: { text: i18n.t('AlertId'), value: 'id' },
      resource: { text: i18n.t('Resource'), value: 'resource' },
      event: { text: i18n.t('Event'), value: 'event' },
      environment: { text: i18n.t('Environment'), value: 'environment' },
      severity: { text: i18n.t('Severity'), value: 'severity' },
      correlate: { text: i18n.t('Correlate'), value: 'correlate' },
      status: { text: i18n.t('Status'), value: 'status' },
      service: { text: i18n.t('Service'), value: 'service' },
      group: { text: i18n.t('Group'), value: 'group' },
      value: { text: i18n.t('Value'), value: 'value', class: 'value-header' },
      text: { text: i18n.t('Description'), value: 'text', class: 'text-header' },
      tags: { text: i18n.t('Tags'), value: 'tags' },
      attributes: { text: i18n.t('Attribute'), value: 'attributes' },
      origin: { text: i18n.t('Origin'), value: 'origin' },
      type: { text: i18n.t('Type'), value: 'type' },
      createTime: { text: i18n.t('CreateTime'), value: 'createTime' },
      timeout: { text: i18n.t('Timeout'), value: 'timeout' },
      timeoutLeft: { text: i18n.t('TimeoutLeft'), value: 'timeoutLeft' },
      customer: { text: i18n.t('Customer'), value: 'customer' },
      duplicateCount: { text: i18n.t('Dupl'), value: 'duplicateCount' },
      repeat: { text: i18n.t('Repeat'), value: 'repeat' },
      previousSeverity: { text: i18n.t('PrevSeverity'), value: 'previousSeverity' },
      trendIndication: { text: i18n.t('TrendIndication'), value: 'trendIndication' },
      receiveTime: { text: i18n.t('ReceiveTime'), value: 'receiveTime' },
      duration: { text: i18n.t('Duration'), value: 'duration' },
      lastReceiveId: { text: i18n.t('LastReceiveId'), value: 'lastReceiveId' },
      lastReceiveTime: { text: i18n.t('LastReceiveTime'), value: 'lastReceiveTime' },
      note: { text: i18n.t('LastNote'), value: 'note', sortable: false }
    },
    details: false,
    selectedId: null,
    multiselect: false,
    timer: null
  }),
  computed: {

    fontStyle() {
      const font = this.$store.getters.getPreference('font')
      return {
        'font-family': font['font-family'],
        'font-size': font['font-size'],
        'font-weight': font['font-weight']
      }
    },
    fontSize() {
      return this.$store.getters.getPreference('font')['font-size']
    },
    columnWidths() {
      return {
        '--value-width': this.valueWidth() + 'px',
        '--text-width': this.textWidth() + 'px'
      }
    },
    isLoading() {
      return this.$store.state.alerts.isLoading
    },
    isSearching() {
      return this.$store.state.alerts.isSearching ? 'primary' : false
    },
    showNotesIcon() {
      return this.$store.getters.getPreference('showNotesIcon')
    },
    rowsPerPage() {
      return this.$store.getters.getPreference('rowsPerPage')
    },
    pagination: {
      get() {
        return this.$store.state.alerts.pagination
      },
      set(value) {
        this.$store.dispatch('alerts/setPagination', value)
      }
    },
    actions() {
      return this.$config.actions
    },
    customHeaders() {
      return this.$config.columns.map(c =>
        this.headersMap[c] || { text: this.$options.filters.capitalize(c), value: 'attributes.' + c }
      )
    },
    selectedItem() {
      return this.alerts.filter(a => a.id == this.selectedId)[0]
    },
    selectableRows() {
      return this.selected.length > 0
    },
    selected: {
      get() {
        return this.$store.state.alerts.selected
      },
      set(value) {
        if (value.length > 0) {
          const lockedStatus = value[0].status
          value = value.filter(item => item.status === lockedStatus)
        }
        this.$store.dispatch('alerts/updateSelected', value)
      }
    },
    ackTimeout() {
      return this.$store.getters.getPreference('ackTimeout')
    },
    shelveTimeout() {
      return this.$store.getters.getPreference('shelveTimeout')
    },
    username() {
      return this.$store.getters['auth/getUsername']
    }
  },
  watch: {
    rowsPerPage(val) {
      this.pagination = Object.assign({}, this.pagination, {rowsPerPage: val})
    }
  },
  methods: {
    duration(item) {
      return moment.duration(moment().diff(moment(item.receiveTime)))
    },
    timeoutLeft(item) {
      let ackedOrShelved = this.isShelved(item.status) || this.isAcked(item.status)
      let lastModified = ackedOrShelved && item.updateTime ? item.updateTime : item.lastReceiveTime
      let expireTime = moment(lastModified).add(item.timeout, 'seconds')
      return expireTime.isAfter() ? expireTime.diff(moment(), 'seconds') : moment.duration()
    },
    lastNote(item) {
      if (!item.history) return null
      const systemTypes = ['new', 'severity', 'status', 'dismiss', 'value']
      return item.history
        .filter(h => {
          if (systemTypes.includes(h.type)) return false
          if (h.type === 'note') return true
          return h.text && h.text.trim() !== ''
        })
        .pop() || null
    },
    valueWidth() {
      return this.$store.getters.getPreference('valueWidth')
    },
    textWidth() {
      return this.$store.getters.getPreference('textWidth')
    },
    severityColor(severity) {
      const colors = this.$store.getters.getConfig('colors')
      if (colors && colors.severity && colors.severity[severity]) {
        return colors.severity[severity]
      }
      const alarmModel = this.$store.getters.getConfig('alarm_model')
      if (alarmModel && alarmModel.colors && alarmModel.colors.severity && alarmModel.colors.severity[severity]) {
        return alarmModel.colors.severity[severity]
      }
      return 'white'
    },
    selectItem(item) {
      if (!this.selected.length) {
        this.$emit('set-alert', item)
      }
    },
    isOpen(status) {
      return status == 'open' || status == 'NORM' || status == 'UNACK' || status == 'RTNUN'
    },
    isAcked(status) {
      return status == 'ack' || status == 'ACKED'
    },
    isShelved(status) {
      return status == 'shelved' || status == 'SHLVD'
    },
    isClosed(status) {
      return status == 'closed'
    },
    takeAction: debounce(function(id, action) {
      this.$store
        .dispatch('alerts/takeAction', [id, action, ''])
        .then(() => this.$store.dispatch('alerts/getAlerts'))
    }, 200, {leading: true, trailing: false}),
    ackAlert: debounce(function(id) {
      this.$store
        .dispatch('alerts/takeAction', [id, 'ack', '', this.ackTimeout])
        .then(() => this.$store.dispatch('alerts/getAlerts'))
    }, 200, {leading: true, trailing: false}),
    shelveAlert: debounce(function(id) {
      this.$store
        .dispatch('alerts/takeAction', [id, 'shelve', '', this.shelveTimeout])
        .then(() => this.$store.dispatch('alerts/getAlerts'))
    }, 200, {leading: true, trailing: false}),
    deleteAlert: debounce(function(id) {
      confirm(i18n.t('ConfirmDelete')) &&
        this.$store.dispatch('alerts/deleteAlert', id)
          .then(() => this.$store.dispatch('alerts/getAlerts'))
    }, 200, {leading: true, trailing: false}),
    clipboardCopy(text) {
      let textarea = document.createElement('textarea')
      textarea.textContent = text
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand('copy')
      document.body.removeChild(textarea)
    }
  }
}
</script>

<style>
.value-header {
  width: var(--value-width);
  min-width: var(--value-width);
}

.text-header {
  width: var(--text-width);
  min-width: var(--text-width);
}

.comfortable table.v-table tbody td, table.v-table tbody th {
  height: 42px !important;
}

.compact table.v-table tbody td, table.v-table tbody th {
  height: 34px !important;
}

.alert-table .v-table tbody td {
  border-top: 1px solid rgb(221, 221, 221);
}

.fixed-table {
  display: table;
  table-layout: fixed;
  width: 100%;
}

i.trend-arrow {
  width: 24px !important;
}

div.select-box {
  width: 24px !important;
}

.label {
  font-weight: bold;
  line-height: 14px;
  color: #ffffff;
  text-shadow: 0 -1px 0 rgba(0, 0, 0, 0.25);
  white-space: nowrap;
  vertical-align: baseline;
  background-color: #999999;
}

.label {
  padding: 1px 4px 2px;
  -webkit-border-radius: 3px;
  -moz-border-radius: 3px;
  border-radius: 3px;
}

.label-inverse {
  background-color: #333333;
}

.hover-lighten:hover {
  filter: brightness(0.87);
}

.btn--plain {
  height: auto;
  width: auto;
  margin: 0;
  padding: 8px;
  min-width: 0;
  font-size: 24px;
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

div.action-buttons {
  position: absolute;
  opacity: 0;
  right: 0;
  top: 50%;
  transform: translateY(-50%);
  height: 2em;
  z-index: 2;
  display: flex;
  align-items: center;
  white-space: nowrap;
}

tr {
  position: relative;
}

tr:hover div.action-buttons {
  opacity: 1;
}
</style>
