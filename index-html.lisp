
(asdf:operate 'asdf:load-op 'gtfl)

(in-package :gtfl)

(define-css 'documentation "
h3 {margin-top:40px;}
div.abstract > * { margin-left:40px;}
p.description-header { margin-top:40px; margin-bottom:20px; }
.description { margin-left:40px;}
pre { background-color:#e0e0e0;padding:3px;display:table;margin-bottom:15px; }
p + pre { margin-top:-10px;}
div.example { border-left:4px solid red;padding-left:20px;margin-top:5px;margin-bottom:20px;}
a { text-decoration:none; }
a:hover, h3 {text-decoration: underline}
tt {white-space:nowrap;display:inline-block;}
")

(defun escape-id (id)
  (regex-replace-all "[/*]" id "_"))

(defun link (text &key id (tt t))
  (who (:a :href (conc "#" (escape-id (or id text)))
           (if tt (htm (:tt (princ text))) (princ text)))))

(defun contents-line (text &key id (tt t))
  (who (:li (link text :id (or id text) :tt tt))))

(defmacro description-header (type name parameters &optional result)
  `(who (:p :class "description-header" :id (escape-id ,name)
            "[" ,type "]" (:br) (:b ,name " ") (:i ,@parameters)
            ,@(when result `(" "(:tt "=>") " " (:i ,result))))))

(defmacro description (&rest content)
  `(who (:p :class "description" ,@content)))

(defun arrow ()
  (who (:tt :style "color:red" "=>")))


(defun abstract ()
  (who 
   (:div 
    :class "abstract"
    (:h3 "Abstract")
    (:p "HT-SIMPLE-AJAX is an " 
        (:a :href "http://en.wikipedia.org/wiki/Ajax_(programming)" "Ajax")
        " library for the "
        (:a :href "http://www.weitz.de/hunchentoot/" "HUNCHENTOOT") 
        " web server. It allows to call ordinary Lisp functions from
          within an html page using javascript and asynchronous
          client/server communication.")
    (:p "It is a heavily simplified (150 lines of code) version of "
        (:a :href "http://www.cliki.net/HT-AJAX" "HT-AJAX")
        " that is compatible with newer versions (>1.1) of
        HUNCHENTOOT. It was initially developed for " 
        (:a :href "http://martin-loetzsch.de/gtfl" "GTFL")
        " and therefore provides only one type of Ajax processor (which
         resembles the 'simple' processor of "
        (:a :href "http://www.cliki.net/HT-AJAX" "HT-AJAX")
        ").")
    (:p "HT-SIMPLE-AJAX comes with a " 
        (:a :href "http://www.opensource.org/licenses/bsd-license.php"
            "BSD-style license")
        " so you can basically do with it whatever you want.")
    (:p (:span :style "color:red" "Download shortcut:") " "
        (:a :href "http://martin-loetzsch.de/ht-simple-ajax/ht-simple-ajax.tar.gz"
            "http://martin-loetzsch.de/ht-simple-ajax/ht-simple-ajax.tar.gz") ".")
    (:p (:span "Github:") " "
        (:a :href "https://github.com/martin-loetzsch/ht-simple-ajax"
            "https://github.com/martin-loetzsch/ht-simple-ajax")))))
         
        
    

(defun table-of-contents ()
  (who 
   (:h3 "Contents")
   (:ol 
    (contents-line "Download and installation" 
                   :id "download-and-installation" :tt nil)
    (:li (link "Example" :id "example" :tt nil))
    (:li (link "The HT-SIMPLE-AJAX dictionary" :id "dictionary" :tt nil)
         (:ol (contents-line "ajax-processor")
              (contents-line "create-ajax-dispatcher")
              (contents-line "defun-ajax")
              (contents-line "generate-prologue")))
    (contents-line "Acknowledgements" :id "acknowledgements" :tt nil))))


(defun download-and-installation ()
  (who
   (:h3 :id "download-and-installation" "Download and installation" )
   (:p "HT-SIMPLE-AJAX together with an example and this documentation can be downloaded from "
       (:a :href "http://martin-loetzsch.de/ht-simple-ajax/ht-simple-ajax.tar.gz"
           "http://martin-loetzsch.de/ht-simple-ajax/ht-simple-ajax.tar.gz") 
       ". The current version is " 
       (princ (asdf:component-version (asdf:find-system :ht-simple-ajax))) ".")
   (:p "HT-SIMPLE-AJAX depends on the "
       (:a :href "http://www.weitz.de/hunchentoot/" "HUNCHENTOOT") 
       " (version >= 1.2.x) web server, which itself requires quite a
        number of other libraries.")
   (:p "If you don't want to download all these libraries manually, you can use "
       (:a :href "http://www.quicklisp.org/" "Quicklisp") " or "
       (:a :href "http://www.cliki.net/ASDF-Install" "ASDF-INSTALL") ":")
   (:pre "(ql:quickload \"ht-simple-ajax\")")
   (:pre "(asdf-install:install 'ht-simple-ajax)")
   (:p "Once everything is installed, HT-SIMPLE-AJAX is compiled and loaded with:")
   (:pre "(asdf:operate 'asdf:load-op :ht-simple-ajax)")))

(defun example ()
  (who
   (:h3 :id "example" "Example" )
   (:p "This is a brief walk-through of ht-simple-ajax. You can try
        out the whole example in "
       (:a :href "demo.lisp" "demo.lisp") " (also contained in the release).")
   (:p "First we create an ajax processor that will handle our
        function calls:")
   (:pre "(defparameter *ajax-processor* 
  (make-instance '" (link "ajax-processor") " :server-uri \"/ajax\"))")
   (:p "Now we can define a function that we want to call from
a web page. This function will take 'name' as an argument 
and return a string with a greeting:")
   (:pre "(" (link "defun-ajax") " say-hi (name) (*ajax-processor*)
  (concatenate 'string \"Hi \" name \", nice to meet you.\"))")
   (:p "We can call this function from Lisp, for example if we want to
        test it:")
   (:pre "HT-SIMPLE-AJAX> (say-hi \"Martin\")
\"Hi Martin, nice to meet you.\"")
   (:p "Next, we setup and start a hunchentoot web server:")
   (:pre "(defparameter *my-server* 
  (start (make-instance 'easy-acceptor :address \"localhost\" :port 8000)))")
   (:p "We add our ajax processor to the hunchentoot dispatch table:")
   (:pre "(setq *dispatch-table* (list 'dispatch-easy-handlers 
                             (" (link "create-ajax-dispatcher") " *ajax-processor*)))")
   (:p "Now we can already call the function from a http client:")
   (:pre "$ curl localhost:8000/ajax/SAY-HI?name=Martin
&lt;?xml version=\"1.0\"?>
&lt;response xmlns='http://www.w3.org/1999/xhtml'>Hi Martin, nice to meet you.&lt;/response>")
   (:p "Alternatively, you can also paste the url above in a web browser")
   (:p "To conveniently call our function from within javascript, the
        ajax processor can create a html script element with generated
        javascript functions for each Lisp function:")
   (:pre "HT-SIMPLE-AJAX> (" (link "generate-prologue") " *ajax-processor*)
\"&lt;script type='text/javascript'>
//&lt;![CDATA[ 
function ajax_call(func, callback, args) {
  // .. some helper code 
}

function ajax_say_hi (name, callback) {
    ajax_call('SAY-HI', callback, [name]);
}
//]]>
&lt;/script>\"")
   (:p "So for our example, the javascript function " (:tt "ajax_say_hi")
       " was generated. " (:tt "name") " is the parameter of the Lisp
        function (if there are multiple parameters, then they will
        also appear here) and " (:tt "callback") " is a function that
        will be asynchronously called when the response comes back
        from the web server. That function takes 1 argument, which is
        the xml DOM object of the response.")
   (:p "Finally, we can put everything together and create a page that
calls our function. For rendering html, we will use "
       (:a :href "http://weitz.de/cl-who/" "cl-who") 
       " in this example (note that ht-simple-ajax can be used
        with any other template/ rendering system):")
   (:pre "(define-easy-handler (main-page :uri \"/\") ()
  (with-html-output-to-string (*standard-output* nil :prologue t)
    (:html :xmlns \"http://www.w3.org/1999/xhtml\"
     (:head
      (:title \"ht-simple-ajax demo\")
      (princ (" (link "generate-prologue") " *ajax-processor*))
      (:script :type \"text/javascript\" \"
// will show the greeting in a message box
function callback(response) {
  alert(response.firstChild.firstChild.nodeValue);
}

// calls our Lisp function with the value of the text field
function sayHi() {
  ajax_say_hi(document.getElementById('name').value, callback);
}
\"))
     (:body
      (:p \"Please enter your name: \" 
          (:input :id \"name\" :type \"text\"))
      (:p (:a :href \"javascript:sayHi()\" \"Say Hi!\"))))))")
   (:p "Direct your web browser to " (:i "http://localhost:8000") 
       " and try it out!")))

(defun dictionary ()
  (who
   (:h3 :id "dictionary" "The HT-SIMPLE-AJAX dictionary" )
   (:p "You can also directly look at " 
       (:a :href "ht-simple-ajax.lisp" "ht-simple-ajax.lisp")
       ", it's fairly simple.")
   (description-header "Standard class" "ajax-processor" nil)
   (description 
    "Maintains a list of lisp function that can be called from a
     client page.")
   (description 
    (:tt ":server-uri") 
    " defines the absolute url for handling http ajax
     requests (default " (:tt "&quot;/ajax&quot;") ").")
   (description 
    (:tt ":content-type") 
    " defines the http content type header for XML responses (default "
    (:tt "&quot;text/xml; charset=\\&quot;utf-8\\&quot;&quot;") ").")
   (description 
    (:tt ":reply-external-format") 
    " determines the format for the character output stream (default "
    (:tt "hunchentoot::+utf-8+") ").")
   (description-header "Function" "create-ajax-dispatcher" ("processor")
                       "dispatcher function")
   (description 
    "Creates a hunchentoot dispatcher function that handles incoming
     ajax requests. " (:i "processor") " is an instance of " 
    (link "ajax-processor") ".")
   (description-header "Macro" "defun-ajax" 
                       ("name params (processor) " (:tt "&amp;body") " body")
                       "no values")
   (description 
    "Declares a defun that can be called from a client page. "
    (:i "processor") " is an instance of " (link "ajax-processor") ".")
   (description "See example above.")
   (description-header "Function" "generate-prologue" 
                       ("processor") "string")
   (description 
    "Creates a " (:tt "&lt;script> ... &lt;/script>")
    " html element that contains all the client-side javascript code
     for the ajax communication. Include this script in the "
    (:tt "&lt;head> &lt;/head>") " element of each html page. "
    (:i "processor") " is an instance of " (link "ajax-processor") ".")))



(defun acknowledgements ()
  (who
   (:h3 :id "acknowledgements" "Acknowledgements")
   (:p "All credits should go to the original author of "
       (:a :href "http://www.cliki.net/HT-AJAX" "HT-AJAX")
       ", who unfortunately doesn't maintain that library anymore.")
   (:p "The layout and structure of this page is heavily inspired
       by (or directly copied from) "
       (:a :href "http://weitz.de/documentation-template/"
           "DOCUMENTATION-TEMPLATE") ".")
   (:p "Last change: "
       (let ((time (multiple-value-list (get-decoded-time))))
         (format t "~a/~2,'0d/~2,'0d ~2,'0d:~2,'0d:~2,'0d"
                 (sixth time) (fifth time) (fourth time)
                 (third time) (second time) (first time)))
       " by " (:a :href "http://martin-loetzsch.de/" "Martin Loetzsch"))))
 


(defun analytics-pixel ()
  (who
   (:script :src "http://www.google-analytics.com/ga.js" 
            :type "text/javascript")
   (:script :type "text/javascript" "
try { var pageTracker = _gat._getTracker('UA-12372300-1'); pageTracker._trackPageview();} catch(err) {}
")))




(defparameter *target* (merge-pathnames 
                        (asdf:component-pathname (asdf:find-system :ht-simple-ajax))
                        (make-pathname :name "index" :type "html")))


(with-open-file (*standard-output* *target*  :direction :output 
                                   :if-exists :supersede )
  (with-html-output (*standard-output* nil :prologue t)
    (:html 
     :xmlns "http://www.w3.org/1999/xhtml"
     (:head
      (:title "HT-SIMPLE-AJAX - Another Ajax library for Hunchentoot" )
      (:script :type "text/javascript" "//<![CDATA[ "
               (loop for definition being the hash-values of *js-definitions*
                  do (princ definition)) " //]]>")
      (:style :type "text/css" 
              (loop for definition being the hash-values of *css-definitions*
                 do (write-string definition))))
     (:body    
      (:h1 "HT-SIMPLE-AJAX - Another Ajax library for Hunchentoot")
      (abstract)
      (table-of-contents)
      (download-and-installation)
      (example)
      (dictionary)
      (acknowledgements)
      (analytics-pixel)
      ))))


;; on macosx this also opens the page in the default browser
;;(asdf:run-shell-command (format nil "open ~a" *target*))















