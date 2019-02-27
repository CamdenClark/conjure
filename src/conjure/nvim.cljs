(ns conjure.nvim
  "Wrapper around all nvim functions."
  (:require [cljs.nodejs :as node]
            [cljs.core.async :as a]
            [clojure.string :as str]
            [applied-science.js-interop :as j]
            [conjure.util :as util]))

(defonce plugin! (atom nil))
(defonce api! (atom nil))

(defn require-api! []
  (-> (node/require "neovim/scripts/nvim")
      (.then #(reset! api! %))))

(defn reset-plugin! [plugin]
  (reset! plugin! plugin)
  (reset! api! (j/get plugin :nvim)))

(defn- join [args]
  (str/join " " (remove nil? args)))

(defn <buffer []
  (-> (j/get @api! :buffer)
      (util/->chan)))

(defn <window []
  (-> (j/get @api! :window)
      (util/->chan)))

(defn <path [buffer]
  (-> (j/get buffer :name)
      (util/->chan)))

(defn <length [buffer]
  (-> (j/get buffer :length)
      (util/->chan)))

(defn append! [buffer & args]
  (j/call buffer :append (join args)))

(defn set-width! [window width]
  (j/assoc! window :width width))

(defn set-cursor! [window {:keys [x y]}]
  (j/assoc! window :cursor #js [y x]))

(defn scroll-to-bottom! [window]
  (a/go
    (let [buffer (a/<! (<buffer))
          length (a/<! (<length buffer))]
      (set-cursor! window {:x 0, :y length}))))

(defn out-write! [& args]
  (j/call @api! :outWrite (join args)))

(defn out-write-line! [& args]
  (j/call @api! :outWriteLine (join args)))

(defn err-write! [& args]
  (j/call @api! :errWrite (join args)))

(defn err-write-line! [& args]
  (j/call @api! :errWriteLine (join args)))

(defn register-command!
  ([k f] (register-command! k f {}))
  ([k f opts]
   (j/call @plugin! :registerCommand
           (name k)
           (fn [s]
             (try
               (f (str s))
               (catch :default e
                 (err-write-line! e))))
           (util/->js opts))))
