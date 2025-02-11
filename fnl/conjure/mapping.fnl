(module conjure.mapping
  {autoload {nvim conjure.aniseed.nvim
             a conjure.aniseed.core
             str conjure.aniseed.string
             config conjure.config
             extract conjure.extract
             log conjure.log
             client conjure.client
             eval conjure.eval
             bridge conjure.bridge
             school conjure.school
             util conjure.util}
   require-macros [conjure.macros]})

(defn- cfg [k]
  (config.get-in [:mapping k]))

(defn- vim-repeat [mapping]
  (.. "repeat#set(\"" (nvim.fn.escape mapping "\"") "\", 1)"))

(defn buf [name-suffix mapping-suffix handler-fn opts]
  "Successor to buf, allows mapping to a Lua function.
  opts: {:desc ""
         :mode :n
         :buf 0
         :command-opts {}
         :mapping-opts {}}"

  (when mapping-suffix
    (let [;; A string is just keys, a table containing a string is an obscure
          ;; way of telling this function that you don't want to prefix the keys
          ;; with the normal Conjure prefix. It's kind of weird and I'd do it
          ;; differently if I designed it from scratch, but here we are.
          mapping (if (a.string? mapping-suffix)
                    (.. (cfg :prefix) mapping-suffix)
                    (a.first mapping-suffix))
          cmd (.. :Conjure name-suffix)
          desc (or (a.get opts :desc) (.. "Executes the " cmd " command"))]
      (nvim.create_user_command
        cmd handler-fn
        (a.merge!
          {:force true
           :desc desc}
          (a.get opts :command-opts {})))
      (nvim.buf_set_keymap
        (a.get opts :buf 0)
        (a.get opts :mode :n)
        mapping
        "" ;; nop because we're using a :callback function.
        (a.merge!
          {:silent true
           :noremap true
           :desc desc
           :callback (fn []
                       (when (not= false (a.get opts :repeat?))
                         (pcall
                           nvim.fn.repeat#set
                           (util.replace-termcodes mapping)
                           1))

                       ;; Have to call like this to pass visual selections through.
                       (nvim.ex.normal_ (str.join [":" cmd (util.replace-termcodes "<cr>")])))}
          (a.get opts :mapping-opts {}))))))

(defn on-filetype []
  (buf
    :LogSplit (cfg :log_split)
    (util.wrap-require-fn-call :conjure.log :split)
    {:desc "Open log in new horizontal split window"})

  (buf
    :LogVSplit (cfg :log_vsplit)
    (util.wrap-require-fn-call :conjure.log :vsplit)
    {:desc "Open log in new vertical split window"})

  (buf
    :LogTab (cfg :log_tab)
    (util.wrap-require-fn-call :conjure.log :tab)
    {:desc "Open log in new tab"})

  (buf
    :LogBuf (cfg :log_buf)
    (util.wrap-require-fn-call :conjure.log :buf)
    {:desc "Open log in new buffer"})

  (buf
    :LogToggle (cfg :log_toggle)
    (util.wrap-require-fn-call :conjure.log :toggle)
    {:desc "Toggle log buffer"})

  (buf
    :LogCloseVisible (cfg :log_close_visible)
    (util.wrap-require-fn-call :conjure.log :close-visible)
    {:desc "Close all visible log windows"})

  (buf
    :LogResetSoft (cfg :log_reset_soft)
    (util.wrap-require-fn-call :conjure.log :reset-soft)
    {:desc "Soft reset log"})

  (buf
    :LogResetHard (cfg :log_reset_hard)
    (util.wrap-require-fn-call :conjure.log :reset-hard)
    {:desc "Hard reset log"})

  (buf
    :LogJumpToLatest (cfg :log_jump_to_latest)
    (util.wrap-require-fn-call :conjure.log :jump-to-latest)
    {:desc "Jump to latest part of log"})

  (buf
    :EvalMotion (cfg :eval_motion)
    (fn []
      (set nvim.o.opfunc :ConjureEvalMotionOpFunc)

      ;; Doesn't work unless we schedule it :( this might break some things.
      (client.schedule #(nvim.feedkeys "g@" :m false)))
    {:desc "Evaluate motion"})

  (buf
    :EvalCurrentForm (cfg :eval_current_form)
    (util.wrap-require-fn-call :conjure.eval :current-form)
    {:desc "Evaluate current form"})

  (buf
    :EvalCommentCurrentForm (cfg :eval_comment_current_form)
    (util.wrap-require-fn-call :conjure.eval :comment-current-form)
    {:desc "Evaluate current form and comment result"})

  (buf
    :EvalRootForm (cfg :eval_root_form)
    (util.wrap-require-fn-call :conjure.eval :root-form)
    {:desc "Evaluate root form"})

  (buf
    :EvalCommentRootForm (cfg :eval_comment_root_form)
    (util.wrap-require-fn-call :conjure.eval :comment-root-form)
    {:desc "Evaluate root form and comment result"})

  (buf
    :EvalWord (cfg :eval_word)
    (util.wrap-require-fn-call :conjure.eval :word)
    {:desc "Evaluate word"})

  (buf
    :EvalCommentWord (cfg :eval_comment_word)
    (util.wrap-require-fn-call :conjure.eval :comment-word)
    {:desc "Evaluate word and comment result"})

  (buf
    :EvalReplaceForm (cfg :eval_replace_form)
    (util.wrap-require-fn-call :conjure.eval :replace-form)
    {:desc "Evaluate form and replace with result"})

  (buf
    :EvalMarkedForm (cfg :eval_marked_form)
    #(client.schedule eval.marked-form)
    {:desc "Evaluate marked form"
     :repeat? false})

  (buf
    :EvalFile (cfg :eval_file)
    (util.wrap-require-fn-call :conjure.eval :file)
    {:desc "Evaluate file"})

  (buf
    :EvalBuf (cfg :eval_buf)
    (util.wrap-require-fn-call :conjure.eval :buf)
    {:desc "Evaluate buffer"})

  (buf
    :EvalVisual (cfg :eval_visual)
    (util.wrap-require-fn-call :conjure.eval :selection)
    {:desc "Evaluate visual select"
     :mode :v
     :command-opts {:range true}})

  (buf
    :DocWord (cfg :doc_word)
    (util.wrap-require-fn-call :conjure.eval :doc-word)
    {:desc "Get documentation under cursor"})

  (buf
    :DefWord (cfg :def_word)
    (util.wrap-require-fn-call :conjure.eval :def-word)
    {:desc "Get definition under cursor"})

  (let [fn-name (config.get-in [:completion :omnifunc])]
    (when fn-name
      (nvim.ex.setlocal (.. "omnifunc=" fn-name))))

  (client.optional-call :on-filetype))

(defn on-exit []
  (client.each-loaded-client #(client.optional-call :on-exit)))

(defn on-quit []
  (log.close-hud))

(defn init [filetypes]
  (nvim.ex.augroup :conjure_init_filetypes)
  (nvim.ex.autocmd_)
  (nvim.ex.autocmd
    :FileType (str.join "," filetypes)
    (bridge.viml->lua :conjure.mapping :on-filetype {}))

  (nvim.ex.autocmd
    :CursorMoved :*
    (bridge.viml->lua :conjure.log :close-hud-passive {}))
  (nvim.ex.autocmd
    :CursorMovedI :*
    (bridge.viml->lua :conjure.log :close-hud-passive {}))

  (nvim.ex.autocmd
    :CursorMoved :*
    (bridge.viml->lua :conjure.inline :clear {}))
  (nvim.ex.autocmd
    :CursorMovedI :*
    (bridge.viml->lua :conjure.inline :clear {}))

  (nvim.ex.autocmd
    :VimLeavePre :*
    (bridge.viml->lua :conjure.log :clear-close-hud-passive-timer {}))
  (nvim.ex.autocmd :ExitPre :* (viml->fn on-exit))
  (nvim.ex.autocmd :QuitPre :* (viml->fn on-quit))
  (nvim.ex.augroup :END))

(defn eval-ranged-command [start end code]
  (if (= "" code)
    (eval.range (a.dec start) end)
    (eval.command code)))

(defn connect-command [...]
  (let [args [...]]
    (client.call
      :connect
      (if (= 1 (a.count args))
        (let [(host port) (string.match (a.first args) "([a-zA-Z%d\\.-]+):(%d+)$")]
          (if (and host port)
            {:host host :port port}
            {:port (a.first args)}))
        {:host (a.first args)
         :port (a.second args)}))))

(defn client-state-command [state-key]
  (if (a.empty? state-key)
    (a.println (client.state-key))
    (client.set-state-key! state-key)))

(defn omnifunc [find-start? base]
  (if find-start?
    (let [[row col] (nvim.win_get_cursor 0)
          [line] (nvim.buf_get_lines 0 (a.dec row) row false)]
      (- col
         (a.count (nvim.fn.matchstr
                    (string.sub line 1 col)
                    "\\k\\+$"))))
    (eval.completions-sync base)))

(nvim.ex.function_
  (->> ["ConjureEvalMotionOpFunc(kind)"
        "call luaeval(\"require('conjure.eval')['selection'](_A)\", a:kind)"
        "endfunction"]
       (str.join "\n")))

(nvim.ex.function_
  (->> ["ConjureOmnifunc(findstart, base)"
        "return luaeval(\"require('conjure.mapping')['omnifunc'](_A[1] == 1, _A[2])\", [a:findstart, a:base])"
        "endfunction"]
       (str.join "\n")))

(nvim.create_user_command
  "ConjureEval"
  #(eval-ranged-command (. $ :line1) (. $ :line2) (. $ :args))
  {:nargs "?"
   :range true })

(nvim.create_user_command
  "ConjureConnect"
  #(connect-command (unpack (. $ :fargs)))
  {:nargs "*"
   :range true
   :complete :file})

(nvim.create_user_command
  "ConjureClientState"
  #(client-state-command (. $ :args))
  {:nargs "?"})

(nvim.create_user_command
  "ConjureSchool"
  #(school.start)
  {})
