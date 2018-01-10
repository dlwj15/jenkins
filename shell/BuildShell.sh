#shell绝对路径
shell_path=$(cd `dirname $0`; pwd)

targetDir=${TargetDir}
if [ ! $targetDir ];then
targetDir=${shell_path}
fi
if [ ! -d ${targetDir}/IPADir ];then
mkdir ${targetDir}/IPADir;
fi

#工程绝对路径
project_path=$(pwd)

#工程名 将XXX替换成自己的工程名
project_name=LiwaiU

#scheme名 将XXX替换成自己的sheme名
scheme_name=LiwaiU

#打包模式 Debug/Release
development_mode=Debug

#info.plist文件
project_infoplist_path="${project_path}/${project_name}/info.plist"
#修改build版本号
if [ $BundleVersion ];then
$(/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BundleVersion}" "${project_infoplist_path}")
fi

#日期
DATE="`date '+%Y-%m-%d%H-%M-%S'`"

#build文件夹路径
build_path=${targetDir}/IPADir/build

#plist文件所在路径
exportOptionsPlistPath=${shell_path}/exportTest.plist

#导出.ipa文件所在路径
exportIpaPath=${targetDir}/IPADir/${project_name}${DATE}
echo 'IPA包存放路径：'${exportIpaPath}

#BundleVersion

#echo "Place enter the number you want to export ? [ 1:app-store 2:ad-hoc] "

##
#read number
#while([[ $number != 1 ]] && [[ $number != 2 ]])
#do
#echo "Error! Should enter 1 or 2"
#echo "Place enter the number you want to export ? [ 1:app-store 2:ad-hoc] "
#read number
#done
number=${type}

if [ $number == 1 ];then
development_mode=Release
exportOptionsPlistPath=${shell_path}/exportAppstore.plist
else
development_mode=Debug
exportOptionsPlistPath=${shell_path}/exportTest.plist
fi


echo '///-----------'
echo '/// 正在清理工程'
echo '///-----------'
xcodebuild \
clean -configuration ${development_mode} -quiet  || exit


echo '///--------'
echo '/// 清理完成'
echo '///--------'
echo ''

echo '///-----------'
echo '/// 正在编译工程:'${development_mode}
echo '///-----------'
xcodebuild \
archive -workspace ${project_path}/${project_name}.xcworkspace \
-scheme ${scheme_name} \
-configuration ${development_mode} \
-archivePath ${build_path}/${project_name}.xcarchive  -quiet  || exit

echo '///--------'
echo '/// 编译完成'
echo '///--------'
echo ''

echo '///----------'
echo '/// 开始ipa打包'
echo '///----------'
xcodebuild -exportArchive -archivePath ${build_path}/${project_name}.xcarchive \
-configuration ${development_mode} \
-exportPath ${exportIpaPath} \
-exportOptionsPlist ${exportOptionsPlistPath} \
-quiet || exit

if [ -e $exportIpaPath/$scheme_name.ipa ]; then
echo '///----------'
echo '/// ipa包已导出'
echo '///----------'
open $exportIpaPath
else
echo '///-------------'
echo '/// ipa包导出失败 '
echo '///-------------'
fi
echo '///------------'
echo '/// 打包ipa完成  '
echo '///-----------='
echo ''

echo '///------------'
echo '/// 删除build文件'
echo '///------------'
rm -rf ${build_path}


if [ $RELEASE == true ];then
echo '///-------------'
echo '/// 开始发布ipa包 '
echo '///-------------'
if [ $number == 1 ];then

#验证并上传到App Store
# 将-u 后面的XXX替换成自己的AppleID的账号，-p后面的XXX替换成自己的密码
altoolPath="/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool"
"$altoolPath" --validate-app -f ${exportIpaPath}/${scheme_name}.ipa -u liulanlan@liwai.com -p Liwai2016 -t ios --output-format xml
"$altoolPath" --upload-app -f ${exportIpaPath}/${scheme_name}.ipa -u  liulanlan@liwai.com -p Liwai2016 -t ios --output-format xml
else

#上传到Fir
# 将XXX替换成自己的Fir平台的token
fir login -T XXX
fir publish $exportIpaPath/$scheme_name.ipa

fi

fi

exit 0

