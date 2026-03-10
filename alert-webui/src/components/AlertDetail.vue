<template>
  <v-card
    flat
  >
    <v-card
      tile
      flat
    >
      <v-toolbar
        :color="isDark ? '#616161' : '#eeeeee'"
        dense
        flat
      >
        <v-btn
          icon
          :title="$t('Back')"
          @click="$emit('close')"
        >
          <v-icon>arrow_back</v-icon>
        </v-btn>

        <v-toolbar-title class="subheading" style="max-width: 280px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
          <span v-if="item && item.event">{{ item.event }}</span>
          <span v-else>告警详情</span>
        </v-toolbar-title>

        <v-spacer />

        <v-btn
          v-if="item && !isWatched(item.tags)"
          icon
          :title="$t('Watch')"
          @click="watchAlert(item.id)"
        >
          <v-icon>visibility</v-icon>
        </v-btn>

        <v-btn
          v-if="item && isWatched(item.tags)"
          icon
          :title="$t('Unwatch')"
          @click="unwatchAlert(item.id)"
        >
          <v-icon>visibility_off</v-icon>
        </v-btn>

        <v-btn
          v-if="item"
          icon
          :title="$t('AddNote')"
          @click="noteDialog = true"
        >
          <v-icon>note_add</v-icon>
        </v-btn>

        <v-btn
          v-if="item"
          icon
          :title="$t('Delete')"
          @click="deleteAlert(item.id)"
        >
          <v-icon>delete</v-icon>
        </v-btn>
      </v-toolbar>

      <v-card
        flat
      >
        <v-tabs
          v-model="active"
          grow
        >
          <v-tab ripple>
            <v-icon>info</v-icon>&nbsp;{{ $t('Details') }}
          </v-tab>
          <v-tab-item
            :transition="false"
            :reverse-transition="false"
          >
            <v-card
              flat
            >
              <v-alert
                v-for="note in notes"
                :key="note.id"
                :value="true"
                dismissible
                type="info"
                class="ma-1"
                @input="deleteNote(item.id, note.id)"
              >
                <b v-if="note.user && note.user.toLowerCase() !== 'anonymous'">{{ note.user }} </b> {{ $t('addedNoteOn') }}
                <span v-if="note.updateTime">
                  <b><date-time
                    :value="note.updateTime"
                    format="longDate"
                  /></b> ({{ note.updateTime | timeago }})<br>
                </span>
                <span v-else>
                  <b><date-time
                    :value="note.createTime"
                    format="longDate"
                  /></b> ({{ note.createTime | timeago }})<br>
                </span>
                <i>{{ note.text }}</i>
              </v-alert>

              <!-- DEPRECATED -->
              <v-alert
                v-for="note in historyNotes"
                :key="note.index"
                type="info"
                class="ma-1"
                :value="true"
              >
                <b v-if="note.user && note.user.toLowerCase() !== 'anonymous'">{{ note.user }} </b> {{ $t('addedNoteOn') }}
                <b><date-time
                  v-if="note.updateTime"
                  :value="note.updateTime"
                  format="longDate"
                /></b> ({{ note.updateTime | timeago }})<br>
                <i>{{ note.text }}</i>
              </v-alert>
              <!-- DEPRECATED -->

              <v-card-text>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('AlertId') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div>
                        <span class="console-text">{{ item.id }}</span>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('LastReceiveAlertId') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div>
                        <span class="console-text">{{ item.lastReceiveId }}</span>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('CreateTime') }}
                      </div>
                    </div>
                    <div class="flex xs9 text-xs-left">
                      <div>
                        <date-time
                          v-if="item.createTime"
                          :value="item.createTime"
                          format="longDate"
                        />
                        ({{ item.createTime | timeago }})
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('ReceiveTime') }}
                      </div>
                    </div>
                    <div class="flex xs9 text-xs-left">
                      <div>
                        <date-time
                          v-if="item.receiveTime"
                          :value="item.receiveTime"
                          format="longDate"
                        />
                        ({{ item.receiveTime | timeago }})
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('LastReceiveTime') }}
                      </div>
                    </div>
                    <div class="flex xs9 text-xs-left">
                      <div>
                        <date-time
                          v-if="item.lastReceiveTime"
                          :value="item.lastReceiveTime"
                          format="longDate"
                        />
                        ({{ item.lastReceiveTime | timeago }})
                      </div>
                    </div>
                  </div>
                </div>
                <div
                  v-if="$config.customer_views"
                  class="flex xs12 ma-1"
                >
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('Customer') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div
                        class="clickable"
                        @click="queryBy('customer', item.customer)"
                      >
                        {{ item.customer }}
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('Service') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div>
                        <span
                          v-for="service in item.service"
                          :key="service"
                          @click="queryBy('service', service)"
                        >
                          <span class="clickable">{{ service }}</span>&nbsp;
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('Environment') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div
                        class="clickable"
                        @click="queryBy('environment', item.environment)"
                      >
                        {{ item.environment }}
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('Resource') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div
                        class="clickable"
                        @click="queryBy('resource', item.resource)"
                      >
                        {{ item.resource }}
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('Description') }}
                      </div>
                    </div>
                    <div class="flex xs9 text-xs-left">
                      <div>
                        {{ item.text }}
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('Correlate') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div>
                        <span
                          v-for="event in item.correlate"
                          :key="event"
                          @click="queryBy('event', event)"
                        >
                          <span class="clickable">{{ event }}</span>&nbsp;
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('Group') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div
                        class="clickable"
                        @click="queryBy('group', item.group)"
                      >
                        {{ item.group }}
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('Severity') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div>
                        <span
                          class="label"
                          :style="{ backgroundColor: severityColor(item.previousSeverity) }"
                        >
                          {{ item.previousSeverity | capitalize }}
                        </span>&nbsp;&rarr;&nbsp;
                        <span
                          class="label"
                          :style="{ backgroundColor: severityColor(item.severity) }"
                        >
                          {{ item.severity | capitalize }}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('Status') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div>
                        <span class="label">
                          {{ item.status | capitalize }}
                        </span>
                        <span
                          v-if="statusNote && statusNote.user"
                        >&nbsp;{{ $t('by') }} <b>{{ statusNote.user }}</b> ({{ statusNote.updateTime | timeago }})
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
                <div
                  v-if="statusNote && statusNote.user && statusNote.text"
                  class="flex xs12 ma-1"
                >
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text" />
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div>
                        <v-icon small>
                          error_outline
                        </v-icon>
                        <i>&nbsp;{{ statusNote.text }}</i>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('Value') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div>
                        {{ item.value }}
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('Description') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div>
                        <span v-html="item.text" />
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('TrendIndication') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div>
                        <span class="label">
                          {{ item.trendIndication | splitCaps }}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('Timeout') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div>
                        {{ item.timeout }}
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('Type') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div>
                        <span class="label">
                          {{ item.type | splitCaps }}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('DuplicateCount') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div>
                        {{ item.duplicateCount }}
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('Repeat') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div>
                        <span class="label">
                          {{ item.repeat | capitalize }}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('Origin') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div
                        class="clickable"
                        @click="queryBy('origin', item.origin)"
                      >
                        {{ item.origin }}
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flex xs12 ma-1">
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ $t('Tags') }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div>
                        <v-chip
                          v-for="tag in item.tags"
                          :key="tag"
                          label
                          small
                          @click="queryBy('tags', tag)"
                        >
                          <v-icon left>
                            label
                          </v-icon>{{ tag }}
                        </v-chip>
                      </div>
                    </div>
                  </div>
                </div>
                <div
                  v-for="(value, attr) in item.attributes"
                  :key="attr"
                  class="flex xs12 ma-1"
                >
                  <div class="d-flex align-top">
                    <div class="flex xs3 text-xs-left">
                      <div class="grey--text">
                        {{ attr | splitCaps }}
                      </div>
                    </div>
                    <div class="flex xs6 text-xs-left">
                      <div
                        v-if="typeof value === 'object'"
                      >
                        <span
                          v-for="v in value"
                          :key="v"
                          @click="queryBy(`_.${attr}`, v)"
                        >
                          <span class="clickable">{{ v }}</span>&nbsp;
                        </span>
                      </div>
                      <div
                        v-else-if="typeof value === 'string' && (value.includes('http://') || value.includes('https://'))"
                        class="link-text"
                        v-html="value"
                      />
                      <div
                        v-else
                        class="clickable"
                        @click="queryBy(`_.${attr}`, value)"
                      >
                        {{ value }}
                      </div>
                    </div>
                  </div>
                </div>
              </v-card-text>
            </v-card>
          </v-tab-item>

          <v-tab ripple>
            <v-icon>history</v-icon>&nbsp;{{ $t('History') }}
          </v-tab>
          <v-tab-item
            :transition="false"
            :reverse-transition="false"
          >
            <div
              class="tab-item-wrapper"
              style="overflow-x: auto; max-height: 80vh;"
            >
              <v-card-text class="pa-0">
                <v-timeline
                  dense
                  clipped
                >
                  <v-timeline-item
                    v-for="(historyItem, index) in history"
                    :key="index"
                    class="severity-timeline-item"
                    :class="'severity-idx-' + index"
                    small
                  >
                    <template slot="icon">
                      <span
                        class="severity-dot-circle"
                        :style="{ backgroundColor: historyDotColor(historyItem) }"
                        :data-severity="historyDotLabel(historyItem)"
                      ></span>
                    </template>
                    <div class="history-row">
                      <div class="history-time">
                        <div class="history-time-main">
                          <date-time :value="historyItem.updateTime" format="shortTime" />
                        </div>
                        <div class="caption grey--text history-time-date">
                          <date-time :value="historyItem.updateTime" format="shortDate" />
                        </div>
                      </div>
                      <div class="history-content">
                        <div class="history-event">{{ historyItem.text || '—' }}</div>
                        <div class="history-tags" style="margin-top: 4px;">
                          <span v-if="historyItem.status" class="label mr-1">{{ historyItem.status | capitalize }}</span>
                          <span v-if="historyItem.user && historyItem.user.toLowerCase() !== 'anonymous'" class="caption grey--text text--lighten-1">by {{ historyItem.user }}</span>
                        </div>
                      </div>
                    </div>
                  </v-timeline-item>
                </v-timeline>
              </v-card-text>
            </div>
          </v-tab-item>

          <v-tab ripple>
            <v-icon>assessment</v-icon>&nbsp;{{ $t('Data') }}
          </v-tab>
          <v-tab-item
            :transition="false"
            :reverse-transition="false"
          >
            <v-card
              :color="isDark ? 'grey darken-1' : 'grey lighten-3'"
              class="mx-1"
              style="overflow-x: auto;"
              flat
            >
              <v-card-text>
                <pre
                  class="console-text"
                  style="white-space: pre-wrap; word-wrap: break-word;"
                >{{ formattedRawData }}</pre>
              </v-card-text>
            </v-card>
          </v-tab-item>
        </v-tabs>
      </v-card>
    </v-card>

    <v-dialog
      v-model="noteDialog"
      max-width="500"
    >
      <v-card>
        <v-card-title class="headline">
          {{ $t('AddNote') }}
        </v-card-title>
        <v-card-text>
          <v-select
            v-model="selectedAction"
            :items="availableActions"
            item-text="text"
            item-value="value"
            :label="$t('Actions')"
          ></v-select>
          <v-text-field
            v-model.trim="noteText"
            :label="$t('Text')"
            autofocus
            @keyup.enter="submitNote"
          />
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn
            flat
            @click="noteDialog = false"
          >
            {{ $t('Cancel') }}
          </v-btn>
          <v-btn
            color="primary"
            flat
            @click="submitNote"
          >
            {{ $t('Submit') }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-card>
</template>

<script>
import debounce from 'lodash/debounce'
import DateTime from './lib/DateTime'
import i18n from '@/plugins/i18n'
import nunjucks from 'nunjucks'

export default {
  components: {
    DateTime
  },
  props: {
    id: {
      type: String,
      required: true
    }
  },
  data: () => ({
    dialog: true,
    sheet: false,
    active: null,
    noteDialog: false,
    noteText: '',
    selectedAction: 'note',
    pagination: {
      rowsPerPage: 10,
      sortBy: 'updateTime',
      descending: true
    },
    headers: [
      { text: i18n.t('AlertOrNoteId'), value: 'id', hide: 'smAndDown' },
      { text: i18n.t('UpdateTime'), value: 'updateTime', hide: 'smAndDown' },
      { text: i18n.t('Updated'), value: 'updateTime', hide: 'mdAndUp' },
      { text: i18n.t('Severity'), value: 'severity', hide: 'smAndDown' },
      { text: i18n.t('Status'), value: 'status', hide: 'smAndDown' },
      { text: i18n.t('Timeout'), value: 'timeout', hide: 'smAndDown' },
      { text: i18n.t('Type'), value: 'type' },
      { text: i18n.t('Event'), value: 'event', hide: 'smAndDown' },
      { text: i18n.t('Value'), value: 'value', hide: 'smAndDown' },
      { text: i18n.t('User'), value: 'user' },
      { text: i18n.t('Text'), value: 'text' }
    ],
    copyIconText: i18n.t('Copy')
  }),
  computed: {
    isDark() {
      return this.$store.getters.getPreference('isDark')
    },
    item() {
      return this.$store.state.alerts.alert
    },
    actions() {
      return this.$config.actions
    },
    history() {
      return this.item.history
        ? this.item.history.map((h, index) => ({ index: index, ...h })).slice().reverse()
        : []
    },
    formattedRawData() {
      if (!this.item.rawData) return 'no raw data'
      if (typeof this.item.rawData === 'string') {
        try {
          const parsed = JSON.parse(this.item.rawData)
          return JSON.stringify(parsed, null, 2)
        } catch (e) {
          return this.item.rawData
        }
      } else if (typeof this.item.rawData === 'object') {
        return JSON.stringify(this.item.rawData, null, 2)
      }
      return this.item.rawData
    },
    notes() {
      return this.$store.state.alerts.notes
    },
    // DEPRECATED: notes stored in alert history are deprecated and will be removed in version 8
    historyNotes() {
      return this.history
        .filter(h => h.type == 'note' && h.id == this.id)  // get notes from alert history
    },
    statusNote() {
      return this.history.filter(h => h.type != 'note' && h.status == this.item.status).pop()
    },
    headersByScreenSize() {
      return this.headers.filter(
        h => !h.hide || !this.$vuetify.breakpoint[h.hide]
      )
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
    refresh() {
      return this.$store.state.refresh
    },
    availableActions() {
      if (!this.item) return []
      const actions = [{ text: this.$t('AddNote'), value: 'note' }]
      const status = this.item.status

      if (this.isOpen(status)) {
        actions.push({ text: this.$t('Ack'), value: 'ack' })
        actions.push({ text: this.$t('Shelve'), value: 'shelve' })
        actions.push({ text: this.$t('Close'), value: 'close' })
      } else if (this.isAcked(status)) {
        actions.push({ text: this.$t('Unack'), value: 'unack' })
        actions.push({ text: this.$t('Shelve'), value: 'shelve' })
        actions.push({ text: this.$t('Close'), value: 'close' })
      } else if (this.isShelved(status)) {
        actions.push({ text: this.$t('Unshelve'), value: 'unshelve' })
        actions.push({ text: this.$t('Close'), value: 'close' })
      } else if (this.isClosed(status)) {
        actions.push({ text: this.$t('Open'), value: 'open' })
      }
      return actions
    }
  },
  watch: {
    dialog(val) {
      val || this.close()
    },
    id(newId) {
      this.active = 0
      this.getAlert(newId)
      this.getNotes(newId)
    },
    refresh(val) {
      if (val) {
        this.getAlert(this.id)
        this.getNotes(this.id)
      }
    },
    noteDialog(val) {
      if (!val) {
        this.selectedAction = 'note'
        this.noteText = ''
      }
    }
  },
  created() {
    this.getAlert(this.id)
    this.getNotes(this.id)
  },
  methods: {
    getAlert() {
      this.$store.dispatch('alerts/getAlert', this.id)
    },
    getNotes() {
      this.$store.dispatch('alerts/getNotes', this.id)
    },
    isOpen(status) {
      return status == 'open' || status == 'NORM' || status == 'UNACK' || status == 'RTNUN'
    },
    isWatched(tags) {
      const tag = `watch:${this.username}`
      return tags ? tags.indexOf(tag) > -1 : false
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
    deleteNote(alertId, noteId) {
      this.$store.dispatch('alerts/deleteNote', [alertId, noteId])
    },
    takeAction: debounce(function(id, action, text) {
      this.$store
        .dispatch('alerts/takeAction', [id, action, text])
        .then(() => this.getAlert(this.id))
    }, 200, {leading: true, trailing: false}),
    ackAlert: debounce(function(id, text) {
      this.$store
        .dispatch('alerts/takeAction', [id, 'ack', text, this.ackTimeout])
        .then(() => this.getAlert(this.id))
    }, 200, {leading: true, trailing: false}),
    shelveAlert: debounce(function(id, text) {
      this.$store
        .dispatch('alerts/takeAction', [id, 'shelve', text, this.shelveTimeout])
        .then(() => this.getAlert(this.id))
    }, 200, {leading: true, trailing: false}),
    watchAlert: debounce(function(id) {
      this.$store
        .dispatch('alerts/watchAlert', id)
        .then(() => this.getAlert(this.id))
    }, 200, {leading: true, trailing: false}),
    unwatchAlert: debounce(function(id) {
      this.$store
        .dispatch('alerts/unwatchAlert', id)
        .then(() => this.getAlert(this.id))
    }, 200, {leading: true, trailing: false}),
    addNote: debounce(function(id, text) {
      this.$store
        .dispatch('alerts/addNote', [id, text])
        .then(() => this.getNotes(this.id))
    }, 200, {leading: true, trailing: false}),
    submitNote() {
      const id = this.item.id
      const text = this.noteText
      if (this.selectedAction === 'note') {
        if (text) {
          this.addNote(id, text)
        }
      } else if (this.selectedAction === 'ack') {
        this.ackAlert(id, text)
      } else if (this.selectedAction === 'shelve') {
        this.shelveAlert(id, text)
      } else {
        this.takeAction(id, this.selectedAction, text)
      }
      this.noteDialog = false
    },
    deleteAlert: debounce(function(id) {
      confirm(i18n.t('ConfirmDelete')) &&
        this.$store.dispatch('alerts/deleteAlert', id)
          .then(() => this.$router.push({ name: 'alerts' }))
    }, 200, {leading: true, trailing: false}),
    queryBy(attribute, value) {
      this.$router.push({ path: `/alerts?q=${attribute}:"${value}"` })  // double-quotes (") around value mean exact match
    },
    close() {
      this.$emit('close')
    },
    clipboardCopy(item) {
      this.copyIconText = i18n.t('Copied')

      let renderedText = this.$config.clipboard_template && nunjucks.renderString(this.$config.clipboard_template, item)

      let text = JSON.stringify(item, null, 4)
      let textarea = document.createElement('textarea')

      textarea.textContent = renderedText || text
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand('copy')
      document.body.removeChild(textarea)
      setTimeout(() => {
        this.copyIconText = i18n.t('Copy')
      }, 2000)
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
      return 'grey'
    },
    historyDotColor(historyItem) {
      if (historyItem.severity) {
        return this.severityColor(historyItem.severity)
      }
      if (historyItem.type === 'note') return '#42A5F5'    // blue for notes
      if (historyItem.type === 'action') return '#78909C'  // blue-grey for actions
      return '#BDBDBD'
    },
    historyDotLabel(historyItem) {
      if (historyItem.severity) {
        const s = historyItem.severity
        return s.charAt(0).toUpperCase() + s.slice(1).toLowerCase()
      }
      if (historyItem.type === 'note') return '备注'
      if (historyItem.type === 'action') return '操作'
      return '状态变化'
    }
  }
}
</script>

<style>
.label {
  font-size: 13px;
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

.v-alert__dismissible {
  margin-top: 8px;
}

.console-text {
  font-size: 14px;
  font-family: Consolas, "Liberation Mono", Menlo, Courier, monospace;
  white-space: pre;
  line-height: 1;
}

div.clickable, span.clickable {
  cursor: pointer;
  color: #3f51b5;
  font-weight: 400;
  text-decoration: underline;
}

.theme--dark div.clickable, .theme--dark span.clickable, .theme--dark div.link-text a {
  color: orange;
}

div.clickable:hover, span.clickable:hover, div.link-text a:hover {
  text-decoration: none;
}

#alerta .v-chip__content {
  cursor: pointer;
}

/* History Timeline Layout */
.history-row {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 4px 0 8px 0;
}

.history-time {
  min-width: 80px;
  flex-shrink: 0;
  text-align: right;
}

.history-time-main {
  font-weight: 600;
  font-size: 13px;
  line-height: 1.4;
}

.history-time-date {
  font-size: 11px;
  line-height: 1.3;
}

.history-content {
  flex: 1;
  min-width: 0;
  line-height: 1.4;
}

.history-event {
  font-size: 13px;
  word-break: break-all;
}

.history-text {
  margin-top: 4px;
  font-size: 12px;
  color: rgba(0, 0, 0, 0.7);
  word-break: break-all;
}

/* Severity-colored dot in history timeline */
.severity-dot-circle {
  display: block;
  width: 14px;
  height: 14px;
  border-radius: 50%;
  cursor: pointer;
  position: relative;
}

/* CSS tooltip: label bubble */
.severity-dot-circle::after {
  content: attr(data-severity);
  position: absolute;
  left: 20px;
  top: 50%;
  transform: translateY(-50%);
  background: rgba(0,0,0,0.75);
  color: #fff;
  font-size: 11px;
  font-weight: 500;
  white-space: nowrap;
  padding: 2px 7px;
  border-radius: 4px;
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.15s;
  z-index: 10;
}

.severity-dot-circle:hover::after {
  opacity: 1;
}

/* Override Vuetify timeline dot - remove default blue ring completely */
.severity-timeline-item .v-timeline-item__dot,
.severity-timeline-item .v-timeline-item__dot--small,
.severity-timeline-item .v-timeline-item__inner-dot {
  background-color: transparent !important;
  box-shadow: none !important;
  border: none !important;
}
</style>
