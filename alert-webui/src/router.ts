import Vue from 'vue'
import VueRouter, { RouterOptions } from 'vue-router'

import { store } from '@/main'

import Alerts from './views/Alerts.vue'
import Alert from './views/Alert.vue'

Vue.use(VueRouter)

export function createRouter(basePath): VueRouter {
  const router = new VueRouter({
    mode: 'history',
    base: basePath || process.env.BASE_URL,
    routes: [
      {
        path: '/alerts',
        name: 'alerts',
        component: Alerts,
        props: route => ({
          query: route.query,
          isKiosk: route.query.kiosk,
          hash: route.hash
        }),
        meta: { title: 'Alerts', requiresAuth: true }
      },
      {
        path: '/alert/:id',
        name: 'alert',
        component: Alert,
        props: true,
        meta: { title: 'Alert Detail', requiresAuth: true }
      },
      {
        path: '/heartbeats',
        name: 'heartbeats',
        component: () => import(/* webpackChunkName: 'user' */ './views/Heartbeats.vue'),
        meta: { title: 'Heartbeats', requiresAuth: true }
      },
      {
        path: '/blackouts',
        name: 'blackouts',
        component: () => import(/* webpackChunkName: 'user' */ './views/Blackouts.vue'),
        meta: { title: 'Blackouts', requiresAuth: true }
      },
      {
        path: '/reports',
        name: 'reports',
        component: () => import(/* webpackChunkName: 'user' */ './views/Reports.vue'),
        meta: { title: 'Reports', requiresAuth: true }
      },
      {
        path: '*',
        redirect: to => {
          // redirect hashbang mode links to HTML5 mode links
          if (to.fullPath.substr(0, 3) === '/#/') {
            return { path: to.fullPath.substr(2), hash: '' }
          }
          return '/alerts'
        }
      }
    ]
  } as RouterOptions)

  // redirect users not logged in to /login if authentication enabled
  router.beforeEach((to, from, next) => {
    if (store.getters.getConfig('auth_required') && to.matched.some(record => record.meta.requiresAuth)) {
      if (!store.getters['auth/isLoggedIn'] && !store.getters.getConfig('allow_readonly')) {
        next({
          path: '/login',
          query: { redirect: to.fullPath }
        })
      } else {
        next()
      }
    } else {
      next()
    }
  })

  router.beforeEach((to, from, next) => {
    if (to?.meta?.title) {
      document.title = to.meta.title + ' | Alerta'
    }
    next()
  })

  router.beforeEach((to, from, next) => {
    let externalUrl = to.fullPath.replace('/', '')
    if (externalUrl.match(/^(http(s)?|ftp):\/\//)) {
      window.open(externalUrl, '_blank')
    } else {
      next()
    }
  })

  return router
}
