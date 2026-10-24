import React,{useEffect,useState} from 'react';
import {SafeAreaView,ScrollView,View,Text,TextInput,TouchableOpacity,StyleSheet,Alert,ActivityIndicator,RefreshControl} from 'react-native';
import {StatusBar} from 'expo-status-bar';
import {API_URL,API_CONFIGURED} from './src/config';

const GREEN='#087443', DARK='#123A2A', MUTED='#66766D', BG='#F4F7F5', BORDER='#E1E9E3';
export default function App(){
 const [kind,setKind]=useState('property'),[q,setQ]=useState(''),[items,setItems]=useState([]),[busy,setBusy]=useState(false),[loading,setLoading]=useState(false),[mode,setMode]=useState('register'),[email,setEmail]=useState(''),[password,setPassword]=useState(''),[name,setName]=useState(''),[token,setToken]=useState(''),[title,setTitle]=useState(''),[description,setDescription]=useState(''),[district,setDistrict]=useState(''),[contact,setContact]=useState('');
 async function load(showError=false){
   if(!API_CONFIGURED){setItems([]);setLoading(false);return}
   setLoading(true);
   try{const r=await fetch(API_URL+'/api/listings?kind='+kind+'&q='+encodeURIComponent(q));const d=await r.json();if(!r.ok)throw Error(d.error||'تعذر تحميل الإعلانات');setItems(Array.isArray(d.listings)?d.listings:[])}
   catch(e){setItems([]);if(showError)Alert.alert('تعذر الاتصال','لم نتمكن من الوصول إلى سيرفر وسيطك. تحقق من اتصال الإنترنت وحالة السيرفر.')}
   finally{setLoading(false);setBusy(false)}
 }
 useEffect(()=>{load()},[kind]);
 async function auth(){
   if(!API_CONFIGURED)return Alert.alert('التطبيق غير مربوط بالسيرفر','لم يتم نشر سيرفر عام للتطبيق بعد. هذه النسخة لا تستطيع التسجيل حتى يتم ربطها بعنوان HTTPS حقيقي.');
   if(!email.trim()||!password)return Alert.alert('راجع البيانات','اكتب البريد الإلكتروني وكلمة السر.');
   if(mode==='register'&&name.trim().length<2)return Alert.alert('راجع الاسم','اكتب اسمًا لا يقل عن حرفين.');
   setBusy(true);
   try{
     const payload=mode==='register'?{name:name.trim(),email:email.trim(),password}:{email:email.trim(),password};
     const r=await fetch(API_URL+(mode==='register'?'/api/register':'/api/login'),{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload)});
     const d=await r.json();if(!r.ok)throw Error(d.error||'تعذر تسجيل الدخول');
     setToken(d.token);Alert.alert('وسيطك',mode==='register'?'تم إنشاء الحساب':'تم تسجيل الدخول');
   }catch(e){Alert.alert('لم يتم إكمال العملية',e.message||'حدث خطأ في الاتصال')}
   finally{setBusy(false)}
 }
 async function add(){
   if(!API_CONFIGURED)return Alert.alert('السيرفر غير جاهز','لا يمكن إرسال إعلان قبل ربط التطبيق بسيرفر عام.');
   if(!token)return Alert.alert('سجّل الدخول أولًا','يلزم تسجيل الدخول قبل إضافة إعلان.');
   if(title.trim().length<4)return Alert.alert('عنوان الإعلان','اكتب عنوانًا من 4 أحرف على الأقل.');
   setBusy(true);
   try{const r=await fetch(API_URL+'/api/listings',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({kind,title:title.trim(),description:description.trim(),city:'بورسعيد',district:district.trim(),contact:contact.trim()})});const d=await r.json();if(!r.ok)throw Error(d.error||'تعذر إرسال الإعلان');Alert.alert('تم الاستلام',d.message||'إعلانك قيد المراجعة');setTitle('');setDescription('');setDistrict('');setContact('');}
   catch(e){Alert.alert('لم يتم إرسال الإعلان',e.message||'تحقق من الاتصال بالسيرفر')}
   finally{setBusy(false)}
 }
 const tab=(value,label)=><TouchableOpacity key={value} style={[s.tab,kind===value&&s.tabOn]} onPress={()=>setKind(value)}><Text style={[s.tabText,kind===value&&s.tabTextOn]}>{label}</Text></TouchableOpacity>;
 const field=(label,value,setter,props={})=><View style={s.field}><Text style={s.label}>{label}</Text><TextInput value={value} onChangeText={setter} placeholderTextColor="#8A9890" style={s.input} {...props}/></View>;
 return <SafeAreaView style={s.safe}><StatusBar style="dark"/><ScrollView contentContainerStyle={s.wrap} keyboardShouldPersistTaps="handled" refreshControl={<RefreshControl refreshing={loading} onRefresh={()=>load(true)} tintColor={GREEN}/>}>
  <View style={s.top}><View><Text style={s.brand}>وسيطك</Text><Text style={s.brandSub}>من بورسعيد لكل مصر</Text></View><View style={s.logo}><Text style={s.logoText}>و</Text></View></View>
  <View style={s.hero}><View style={s.heroTag}><Text style={s.heroTagText}>من بورسعيد • لكل مصر</Text></View><Text style={s.heroTitle}>مكانك المناسب،</Text><Text style={s.heroAccent}>وفرصتك الجاية.</Text><Text style={s.heroDesc}>عقارات ووظائف وباحثون عن عمل، كل ده في مكان واحد.</Text><View style={s.heroStats}><View><Text style={s.statNum}>٣</Text><Text style={s.statLabel}>أقسام رئيسية</Text></View><View style={s.statDivider}/><View><Text style={s.statNum}>بورسعيد</Text><Text style={s.statLabel}>نقطة البداية</Text></View></View></View>
  {!API_CONFIGURED&&<View style={s.notice}><Text style={s.noticeTitle}>التطبيق في مرحلة التجهيز</Text><Text style={s.noticeBody}>السيرفر العام لم يتم ربطه بعد، لذلك تسجيل الحسابات وتحميل الإعلانات لن يعمل في هذه النسخة.</Text></View>}
  <View style={s.sectionHead}><View><Text style={s.sectionTitle}>اكتشف الإعلانات</Text><Text style={s.sectionSub}>اختار القسم ودوّر على اللي يناسبك</Text></View><Text style={s.sectionMark}>01</Text></View>
  <View style={s.tabs}>{tab('property','عقارات')}{tab('job','وظائف')}{tab('seeker','باحث عن عمل')}</View>
  <View style={s.searchBox}><TextInput value={q} onChangeText={setQ} placeholder="ابحث بعنوان أو منطقة..." placeholderTextColor="#8A9890" style={s.searchInput} onSubmitEditing={()=>load(true)} returnKeyType="search"/><TouchableOpacity style={s.searchButton} onPress={()=>load(true)}><Text style={s.searchButtonText}>بحث</Text></TouchableOpacity></View>
  {loading?<ActivityIndicator style={{margin:20}} color={GREEN}/>:items.map(x=><View key={x.id} style={s.listing}><View style={s.listingLine}><View style={s.listingTag}><Text style={s.listingTagText}>{x.kind==='job'?'وظيفة':x.kind==='seeker'?'باحث عن عمل':'عقار'}</Text></View><Text style={s.location}>{[x.district,x.city].filter(Boolean).join('، ')}</Text></View><Text style={s.listingTitle}>{x.title}</Text>{x.description?<Text style={s.listingDesc}>{x.description}</Text>:null}{x.price!=null?<Text style={s.price}>{x.price} جنيه</Text>:null}{x.contact?<Text style={s.contact}>التواصل: {x.contact}</Text>:null}</View>)}
  {!loading&&items.length===0&&<View style={s.empty}><View style={s.emptyIcon}><Text style={s.emptyIconText}>⌕</Text></View><Text style={s.emptyTitle}>{API_CONFIGURED?'لا توجد إعلانات منشورة بعد':'الإعلانات ستظهر هنا'}</Text><Text style={s.emptyBody}>{API_CONFIGURED?'جرّب قسمًا آخر أو ابحث بكلمة مختلفة.':'بمجرد ربط السيرفر ونشر الإعلانات، هتقدر تتصفحها من هنا.'}</Text></View>}
  <View style={s.sectionHead}><View><Text style={s.sectionTitle}>حسابك على وسيطك</Text><Text style={s.sectionSub}>سجّل عشان تتابع إعلاناتك</Text></View><Text style={s.sectionMark}>02</Text></View>
  <View style={s.panel}><View style={s.modeTabs}><TouchableOpacity onPress={()=>setMode('register')} style={[s.modeTab,mode==='register'&&s.modeTabOn]}><Text style={[s.modeText,mode==='register'&&s.modeTextOn]}>حساب جديد</Text></TouchableOpacity><TouchableOpacity onPress={()=>setMode('login')} style={[s.modeTab,mode==='login'&&s.modeTabOn]}><Text style={[s.modeText,mode==='login'&&s.modeTextOn]}>تسجيل الدخول</Text></TouchableOpacity></View>
   {mode==='register'&&field('الاسم بالكامل',name,setName,{placeholder:'اكتب اسمك'})}
   {field('البريد الإلكتروني',email,setEmail,{placeholder:'name@example.com',autoCapitalize:'none',keyboardType:'email-address'})}
   {field('كلمة السر',password,setPassword,{placeholder:'10 أحرف على الأقل',secureTextEntry:true})}
   <TouchableOpacity style={[s.primaryButton,busy&&s.disabled]} disabled={busy} onPress={auth}>{busy?<ActivityIndicator color="#fff"/>:<Text style={s.primaryText}>{mode==='register'?'إنشاء حساب':'دخول إلى حسابي'}</Text>}</TouchableOpacity>
  </View>
  <View style={s.sectionHead}><View><Text style={s.sectionTitle}>عندك إعلان؟</Text><Text style={s.sectionSub}>وصّله للناس اللي بتدور عليه</Text></View><Text style={s.sectionMark}>03</Text></View>
  <View style={s.panel}>{field('عنوان الإعلان',title,setTitle,{placeholder:'مثال: شقة للإيجار في حي العرب'})}{field('المنطقة',district,setDistrict,{placeholder:'مثال: حي العرب'})}{field('وصف الإعلان',description,setDescription,{placeholder:'اكتب التفاصيل المهمة...',multiline:true,textAlignVertical:'top'})}{field('وسيلة التواصل',contact,setContact,{placeholder:'رقم هاتف أو وسيلة تواصل'})}<TouchableOpacity style={s.primaryButton} onPress={add}><Text style={s.primaryText}>إرسال الإعلان للمراجعة</Text></TouchableOpacity><Text style={s.helper}>الإعلانات الجديدة بتحتاج مراجعة قبل النشر.</Text></View>
  <View style={s.footer}><Text style={s.footerBrand}>وسيطك</Text><Text style={s.footerText}>بداية محلية، وفرص أكبر.</Text><Text style={s.copy}>© وسيطك — بورسعيد، مصر</Text></View>
 </ScrollView></SafeAreaView>
}
const s=StyleSheet.create({
 safe:{flex:1,backgroundColor:BG},wrap:{padding:18,paddingBottom:34,gap:16},top:{flexDirection:'row-reverse',alignItems:'center',justifyContent:'space-between',marginBottom:4},brand:{fontSize:31,fontWeight:'900',color:GREEN,textAlign:'right'},brandSub:{fontSize:12,color:MUTED,textAlign:'right',marginTop:1},logo:{width:48,height:48,borderRadius:16,backgroundColor:'#E1F0E7',alignItems:'center',justifyContent:'center',borderWidth:1,borderColor:'#CDE2D4'},logoText:{fontSize:29,fontWeight:'900',color:GREEN},
 hero:{backgroundColor:DARK,borderRadius:25,padding:24,overflow:'hidden'},heroTag:{alignSelf:'flex-end',backgroundColor:'#285441',borderRadius:20,paddingHorizontal:12,paddingVertical:7,marginBottom:22},heroTagText:{fontSize:12,color:'#D8F0E1',fontWeight:'700'},heroTitle:{fontSize:30,fontWeight:'900',color:'#FFF',textAlign:'right'},heroAccent:{fontSize:30,fontWeight:'900',color:'#80D9A5',textAlign:'right',marginTop:2},heroDesc:{fontSize:15,lineHeight:25,color:'#D5E4DB',textAlign:'right',marginTop:14},heroStats:{flexDirection:'row-reverse',alignItems:'center',marginTop:24,paddingTop:18,borderTopWidth:1,borderTopColor:'#345544',gap:22},statNum:{color:'#fff',fontSize:18,fontWeight:'800',textAlign:'right'},statLabel:{color:'#AFC8B8',fontSize:11,marginTop:3,textAlign:'right'},statDivider:{width:1,height:35,backgroundColor:'#416553'},
 notice:{padding:15,borderRadius:15,backgroundColor:'#FFF4DD',borderWidth:1,borderColor:'#F0DDB4'},noticeTitle:{fontSize:15,fontWeight:'800',color:'#855A10',textAlign:'right'},noticeBody:{fontSize:13,lineHeight:21,color:'#745D32',textAlign:'right',marginTop:4},
 sectionHead:{flexDirection:'row-reverse',alignItems:'center',justifyContent:'space-between',marginTop:10},sectionTitle:{fontSize:22,fontWeight:'900',color:DARK,textAlign:'right'},sectionSub:{fontSize:13,color:MUTED,textAlign:'right',marginTop:4},sectionMark:{fontSize:13,fontWeight:'800',color:'#8CA899'},
 tabs:{flexDirection:'row-reverse',gap:8,flexWrap:'wrap'},tab:{paddingVertical:10,paddingHorizontal:14,borderRadius:22,backgroundColor:'#E8EEEA',borderWidth:1,borderColor:'#E0E8E2'},tabOn:{backgroundColor:GREEN,borderColor:GREEN},tabText:{color:'#426052',fontWeight:'700',fontSize:13},tabTextOn:{color:'#fff'},
 searchBox:{flexDirection:'row-reverse',alignItems:'center',gap:8,backgroundColor:'#fff',borderWidth:1,borderColor:BORDER,borderRadius:15,padding:6},searchInput:{flex:1,padding:10,textAlign:'right',fontSize:14,color:DARK,minWidth:0},searchButton:{backgroundColor:GREEN,paddingVertical:12,paddingHorizontal:18,borderRadius:11},searchButtonText:{color:'#fff',fontWeight:'800'},
 listing:{backgroundColor:'#fff',borderRadius:17,padding:16,borderWidth:1,borderColor:BORDER,gap:8},listingLine:{flexDirection:'row-reverse',alignItems:'center',justifyContent:'space-between',gap:8},listingTag:{backgroundColor:'#E4F2E9',paddingHorizontal:9,paddingVertical:5,borderRadius:8},listingTagText:{fontSize:11,fontWeight:'800',color:GREEN},location:{fontSize:12,color:MUTED,textAlign:'right',flexShrink:1},listingTitle:{fontSize:18,fontWeight:'900',color:DARK,textAlign:'right'},listingDesc:{fontSize:14,lineHeight:22,color:'#53665A',textAlign:'right'},price:{color:GREEN,fontSize:16,fontWeight:'900',textAlign:'right'},contact:{color:MUTED,fontSize:13,textAlign:'right'},
 empty:{alignItems:'center',backgroundColor:'#fff',borderRadius:18,borderStyle:'dashed',borderWidth:1,borderColor:'#D6E3D9',padding:24},emptyIcon:{width:53,height:53,borderRadius:18,backgroundColor:'#E9F4ED',alignItems:'center',justifyContent:'center'},emptyIconText:{fontSize:35,color:GREEN},emptyTitle:{fontSize:17,fontWeight:'800',color:DARK,marginTop:12,textAlign:'center'},emptyBody:{fontSize:13,lineHeight:21,color:MUTED,textAlign:'center',marginTop:5},
 panel:{backgroundColor:'#fff',padding:17,borderRadius:19,borderWidth:1,borderColor:BORDER,gap:12},modeTabs:{flexDirection:'row-reverse',backgroundColor:'#F0F4F1',borderRadius:12,padding:4},modeTab:{flex:1,alignItems:'center',padding:10,borderRadius:9},modeTabOn:{backgroundColor:'#fff',elevation:1},modeText:{fontSize:13,fontWeight:'700',color:MUTED},modeTextOn:{color:GREEN},
 field:{gap:6},label:{textAlign:'right',fontSize:13,fontWeight:'800',color:'#42584B'},input:{width:'100%',backgroundColor:'#FBFCFB',borderWidth:1,borderColor:'#DCE6DF',borderRadius:12,padding:13,textAlign:'right',color:DARK,fontSize:14},primaryButton:{backgroundColor:GREEN,padding:15,borderRadius:13,alignItems:'center',justifyContent:'center',minHeight:50},primaryText:{color:'#fff',fontWeight:'900',fontSize:15},disabled:{opacity:.7},helper:{textAlign:'right',fontSize:12,color:MUTED,lineHeight:19},
 footer:{marginTop:6,backgroundColor:'#E7F0EA',borderRadius:18,padding:20,alignItems:'center'},footerBrand:{fontSize:23,fontWeight:'900',color:GREEN},footerText:{fontSize:13,color:'#52685B',marginTop:4},copy:{fontSize:11,color:'#839187',marginTop:16}
});
