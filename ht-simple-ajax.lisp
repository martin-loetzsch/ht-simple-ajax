;;;;; Copyright (c) 2010-2013, Martin Loetzsch
;;;;; All rights reserved.

;;;;; Redistribution and use in source and binary forms, with or
;;;;; without modification, are permitted provided that the following
;;;;; conditions are met:

;;;;;  Redistributions of source code must retain the above copyright
;;;;;  notice, this list of conditions and the following disclaimer.

;;;;;  Redistributions in binary form must reproduce the above
;;;;;  copyright notice, this list of conditions and the following
;;;;;  disclaimer in the documentation and/or other materials provided
;;;;;  with the distribution.

;;;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
;;;;; CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
;;;;; INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
;;;;; MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;;;;; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
;;;;; CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;;;;; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;;;;; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
;;;;; USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
;;;;; AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
;;;;; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
;;;;; IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
;;;;; THE POSSIBILITY OF SUCH DAMAGE.


(cl:defpackage :ht-simple-ajax
  (:use :common-lisp :hunchentoot)
  (:export :ajax-processor :defun-ajax
           :create-ajax-dispatcher :generate-prologue))

(in-package :ht-simple-ajax)


(defclass ajax-processor ()
  ((lisp-fns 
    :accessor lisp-fns :initform (make-hash-table :test #'equal)
    :type hash-table
    :documentation "Maps the symbol names of the exported functions to
                    their symbols")
   (js-fns
    :accessor js-fns :initform (make-hash-table :test #'equal)
    :type hash-table
    :documentation "Maps the symbol names of the exported functions to
                    a javascript code that can call the function from
                    within the client page")
   (server-uri 
    :initarg :server-uri :initform "/ajax" :accessor server-uri
    :type string
    :documentation "The uri which is used to handle ajax request")
   (content-type :initarg :content-type :type string
     :accessor content-type :initform "text/xml; charset=\"utf-8\""
     :documentation "The http content type that is sent with each response")
   (reply-external-format 
    :initarg :reply-external-format :type flexi-streams::external-format
    :accessor reply-external-format :initform hunchentoot::+utf-8+
    :documentation "The format for the character output stream"))
  (:documentation "Maintains a list of lisp function that can be
                   called from a client page."))


(defun create-ajax-dispatcher (processor)
  "Creates a hunchentoot dispatcher for an ajax processor"
  (create-prefix-dispatcher (server-uri processor)
                            #'(lambda () (call-lisp-function processor))))


(defun make-js-symbol (symbol)
  "helper function for making 'foo_bar_' out of 'foo-bar?' "
  (loop with string = (string-downcase symbol)
     for c across "?-<>"
     do (setf string (substitute #\_ c string))
     finally (return string)))


(defmacro defun-ajax (name params (processor) &body body)
  "Declares a defun that can be called from a client page.
Example: (defun-ajax func1 (arg1 arg2) (*ajax-processor*)
   (do-stuff))"
  (let ((js-fn (format nil "

function ~a (~{~a, ~}callback) {
    ajax_call('~a', callback, ~2:*[~{~a~^, ~}]);
}" 
                       (concatenate 'string "ajax_" (make-js-symbol name))
                       (mapcar #'make-js-symbol params) 
                       (symbol-name name))))
    `(progn
       (defun ,name ,params ,@body)
       (setf (gethash (symbol-name ',name) (lisp-fns ,processor)) ',name)
       (setf (gethash (symbol-name ',name) (js-fns ,processor)) ',js-fn))))



(defun generate-prologue (processor)
  "Creates a <script> ... </script> html element that contains all the
   client-side javascript code for the ajax communication. Include this 
   script in the <head> </head> of each html page"
  (apply #'concatenate 'string
         `("<script type='text/javascript'>
//<![CDATA[ 
function fetchURI(uri, callback) {
  var request;
  if (window.XMLHttpRequest) { request = new XMLHttpRequest(); }
  else {
    try { request = new ActiveXObject(\"Msxml2.XMLHTTP\"); } catch (e) {
      try { request = new ActiveXObject(\"Microsoft.XMLHTTP\"); } catch (ee) {
        request = null;
      }}}
  if (!request) alert(\"Browser couldn't make a request object.\");

  request.open('GET', uri, true);
  request.onreadystatechange = function() {
    if (request.readyState != 4) return;
    if (((request.status>=200) && (request.status<300)) || (request.status == 304)) {
      var data = request.responseXML;
      if (callback!=null) { callback(data); }
    }
    else { 
      alert('Error while fetching URI ' + uri);
    }
  }
  request.send(null);
  delete request;
}

function ajax_call(func, callback, args) {
  var uri = '" ,(server-uri processor) "/' + encodeURIComponent(func) + '/';
  var i;
  if (args.length > 0) {
    uri += '?'
    for (i = 0; i < args.length; ++i) {
      if (i > 0) { uri += '&' };
      uri += 'arg' + i + '=' + encodeURIComponent(args[i]);
    }
  }
  fetchURI(uri, callback);
}"
  ,@(loop for js being the hash-values of (js-fns processor)
       collect js)
  "
//]]>
</script>")))



(defun call-lisp-function (processor)
  "This is called from hunchentoot on each ajax request. It parses the 
   parameters from the http request, calls the lisp function and returns
   the response."
  (let* ((fn-name (string-trim "/" (subseq (script-name* *request*)
                                           (length (server-uri processor)))))
         (fn (gethash fn-name (lisp-fns processor)))
         (args (mapcar #'cdr (get-parameters* *request*))))
    (unless fn
      (error "Error in call-lisp-function: no such function: ~A" fn-name))
    
    (setf (reply-external-format*) (reply-external-format processor))
    (setf (content-type*) (content-type processor))
    (no-cache)
    (concatenate 'string "<?xml version=\"1.0\"?>
<response xmlns='http://www.w3.org/1999/xhtml'>"
                 (apply fn args) "</response>")))

