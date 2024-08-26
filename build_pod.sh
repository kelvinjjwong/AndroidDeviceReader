GIT_USER="kelvinjjwong"
GIT_REPOSITORY="AndroidDeviceReader"
GIT_BASE_BRANCH="main"

if [[ "$1" = "help" ]] || [[ "$1" = "--help" ]]  || [[ "$1" = "--?" ]]; then
   echo "Sample:"
   echo "./build_pod.sh"
   echo "./build_pod.sh version up"
   echo "./build_pod.sh version up major"
   echo "./build_pod.sh version up minor"
   echo "./build_pod.sh version up revision"
   echo "./build_pod.sh version down"
   echo "./build_pod.sh version down major"
   echo "./build_pod.sh version down minor"
   echo "./build_pod.sh version down revision"
   echo
   exit 0
fi

xcodebuild -version
if [[ $? -ne 0 ]]; then
    if [[ -e /Applications/Xcode.app/Contents/Developer ]]; then
        sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
        xcodebuild -version
        if [[ $? -ne 0 ]]; then
            exit -1
        fi
    else
        exit -1
    fi
fi

versionPos="revision"
versionChange=0
if [[ "$1 $2" = "version up" ]]; then
   versionChange=1
   if [[ "$3" = "major" ]]; then
       versionPos="major"
   elif [[ "$3" = "minor" ]]; then
       versionPos="minor"
   else
       versionPos="revision"
   fi
fi

if [[ "$1 $2" = "version down" ]]; then
   versionChange=-1
   if [[ "$3" = "major" ]]; then
       versionPos="major"
   elif [[ "$3" = "minor" ]]; then
       versionPos="minor"
   else
       versionPos="revision"
   fi
fi


pod trunk me
if [[ $? -ne 0 ]]; then
  echo "Please register like below before retry: "
  echo
  echo "pod trunk register `defaults read MobileMeAccounts Accounts | grep AccountDescription | awk -F'"' '{print $2}'` '`whoami`' --description='`hostname -s`'"
  echo
  exit -1
fi

# JUMP VERSION

PODSPEC=`ls *.podspec | awk -F' ' '{print $1}' | head -1`
PREV_VERSION=`grep s.version $PODSPEC | head -1 | awk -F' ' '{print $NF}' | sed 's/"//g'`

if [[ $versionChange -ne 0 ]]; then
    if [[ $versionChange -eq 1 ]]; then
        if [[ "$versionPos" = "major" ]]; then
            NEW_VERSION=`echo $PREV_VERSION | awk -F'.' '{print $1+1".0.0"}'`
        elif [[ "$versionPos" = "minor" ]]; then
            NEW_VERSION=`echo $PREV_VERSION | awk -F'.' '{print $1"."$2+1".0"}'`
        else
            NEW_VERSION=`echo $PREV_VERSION | awk -F'.' '{print $1"."$2"."$3+1}'`
        fi
        
    else
        if [[ "$versionPos" = "major" ]]; then
            NEW_VERSION=`echo $PREV_VERSION | awk -F'.' '{print $1-1"."$2"."$3}'`
        elif [[ "$versionPos" = "minor" ]]; then
            NEW_VERSION=`echo $PREV_VERSION | awk -F'.' '{print $1"."$2-1"."$3}'`
        else
            NEW_VERSION=`echo $PREV_VERSION | awk -F'.' '{print $1"."$2"."$3-1}'`
        fi
    fi
    echo "Current version: $PREV_VERSION"
    echo "   Next version: $NEW_VERSION"
    sed -i .bak -e 's/s.version     = ".*"/s.version     = "'$NEW_VERSION'"/' $PODSPEC; rm -f $PODSPEC.bak
    sed -i .bak -e 's/"'$PREV_VERSION'"/"'$NEW_VERSION'"/g' -e 's/~> '$PREV_VERSION'/~> '$NEW_VERSION'/g' README.md; rm -f README.md.bak
fi

# PUSH CHANGES BEFORE POD TESTING

GIT_BRANCH=`git status | grep "On branch" | head -1 | awk -F' ' '{print $NF}'`
CURRENT_VERSION=`grep s.version $PODSPEC | head -1 | awk -F' ' '{print $NF}' | sed 's/"//g'`

GIT_REMOTE_REPO=`git config --get remote.origin.url`
if [ "$GIT_REMOTE_REPO" = "" ]; then
    git remote add origin git@github.com:${GIT_USER}/${GIT_REPOSITORY}.git
    git branch -M ${GIT_BASE_BRANCH}
    git push -u origin ${GIT_BASE_BRANCH}
fi

EXIST_TAG=`git ls-remote --tags origin | tr '/' ' ' | awk -F' ' '{print $NF}' | grep $CURRENT_VERSION`
if [[ "$EXIST_TAG" != "" ]]; then
    echo "$CURRENT_VERSION already exist in git repository. Aborted following build steps to avoid duplication."
    echo
    exit -1
fi

if [[ "$GIT_BRANCH" != "$CURRENT_VERSION" ]]; then
    git branch $CURRENT_VERSION
    git checkout $CURRENT_VERSION
fi
git commit -am "build version $CURRENT_VERSION"
if [[ $? -eq 0 ]]; then
    git push --set-upstream origin $CURRENT_VERSION
    if [[ $? -ne 0 ]]; then
       exit -1
    fi
fi

# POD TESTING

pod spec lint $PODSPEC --allow-warnings
if [[ $? -ne 0 ]]; then
    exit -1
fi

# RELEASE

GH=`which gh`
if [[ "$GH" != "" ]]; then
    gh pr status
    gh pr create --title "$CURRENT_VERSION" --body "**Full Changelog**: https://github.com/${GIT_USER}/${GIT_REPOSITORY}/compare/$PREV_VERSION...$CURRENT_VERSION"
    gh pr list
    GH_PR=`gh pr list | tail -1 | tr '#' ' ' | awk -F' ' '{print $1}'`
    gh pr merge $GH_PR -m
    if [[ $? -ne 0 ]]; then
        exit -1
    fi
    gh pr status
    git pull
    git checkout ${GIT_BASE_BRANCH}
    git pull
    gh release create $CURRENT_VERSION --generate-notes
    if [[ $? -ne 0 ]]; then
        exit -1
    fi
    
    pod trunk push $PODSPEC --allow-warnings
else
    SOURCE_URL=`grep s.source $PODSPEC | head -1 | awk -F'"' '{print $2}' | sed 's/.\{4\}$//'`
    echo "If success, you can then:"
    echo
    echo "1 # publish new release by tagging new version [$CURRENT_VERSION] in git repository"
    echo "$SOURCE_URL/releases"
    echo "with auto markdown release note"
    echo "**Full Changelog**: $SOURCE_URL/compare/$PREV_VERSION...$CURRENT_VERSION"
    echo ""
    echo "2 # push new version to Cocoapods trunk"
    echo "pod trunk push $PODSPEC"
    echo
    echo "OR install GitHub CLI to automate these steps:"
    echo
    echo "brew install gh"
    echo "gh auth login"
    echo
    echo "https://cli.github.com"
    echo
fi
