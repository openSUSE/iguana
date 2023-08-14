from storage import *

class MyCommitCallbacks(CommitCallbacksV2):

    def __init__(self):
        super(MyCommitCallbacks, self).__init__()

    def begin_action(self, action):
        self.action = action

    def end_action(self, action):
        self.action = None

    def message(self, message):
        print("message '%s'" % message)

    def error(self, message, what):
        print("error '%s' '%s'" % (message, what))
        return False
    

def commit(storage, skip_commit = False):
    commit_options = CommitOptions(False)
    my_commit_callbacks = MyCommitCallbacks()
    if not skip_commit:
        try:
            storage.commit(commit_options, my_commit_callbacks)
        except Exception as exception:
            print(exception.what())