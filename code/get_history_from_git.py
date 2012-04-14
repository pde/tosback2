import sys
from git import *

if(len(sys.argv) != 4):
	print "Usage: python get_history_from_git.py REPO_LOCATION REPO_PATH BRANCH"
	sys.exit()

def printCommit(commitHash, commitDate, printed):
	if not printed:
		print "\t{"
	else:
		print ",\n\t{"
	print '\t\tcommitHash: "' + commitHash + '",'
	print "\t\tcommitDate: " +  str(commitDate)
	sys.stdout.write("\t}")

def getHistoryFromGit(repoLocation, repoPath, branch):
	
	try:
		repo = Repo(repoLocation)
		currentCommit = repo.heads[branch].commit
		lastBlobHexSHA = currentCommit.tree[repoPath].hexsha
		lastCommit = currentCommit
		foundBlob = False
		handledFirst = False
		printed = False
		
		print "["
		
		while currentCommit:
			try:
				blob = currentCommit.tree[repoPath]
				foundBlob = True
				if blob.hexsha != lastBlobHexSHA:
					printCommit(lastCommit.hexsha, lastCommit.committed_date, printed)
					printed = True
					lastBlobHexSHA = blob.hexsha
			except KeyError:
				if foundBlob and not handledFirst:
					handledFirst = True
					printCommit(lastCommit.hexsha, lastCommit.committed_date, printed)
					printed = True
					lastBlobHexSHA = blob.hexsha
			if currentCommit.parents:
				lastCommit = currentCommit
				currentCommit = currentCommit.parents[0]
			else:
				currentCommit = None
		
		print "\n]"
	
	except:
		print "[ ]"
	
getHistoryFromGit(sys.argv[1], sys.argv[2], sys.argv[3])